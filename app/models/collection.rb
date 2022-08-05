# frozen_string_literal: true

class Collection < ApplicationRecord
  include Permissions
  include DepositedAtTimestamp
  include ViewStatistics
  include AllDois
  include GeneratedUuids
  include UpdatingDois
  include ThumbnailSelections

  fields_with_dois :doi, :identifier

  attr_writer :indexing_source

  jsonb_accessor :metadata,
                 title: :string,
                 subtitle: :string,
                 keyword: [:string, { array: true, default: [] }],
                 description: :string,
                 contributor: [:string, { array: true, default: [] }],
                 publisher: [:string, { array: true, default: [] }],
                 published_date: :string,
                 subject: [:string, { array: true, default: [] }],
                 language: [:string, { array: true, default: [] }],
                 identifier: [:string, { array: true, default: [] }],
                 based_near: [:string, { array: true, default: [] }],
                 related_url: [:string, { array: true, default: [] }],
                 source: [:string, { array: true, default: [] }]

  belongs_to :depositor,
             class_name: 'Actor',
             foreign_key: 'depositor_id',
             inverse_of: 'deposited_works'

  has_many :legacy_identifiers,
           as: :resource,
           dependent: :destroy

  has_many :collection_work_memberships,
           dependent: :destroy

  has_many :works,
           through: :collection_work_memberships,
           inverse_of: :collections

  has_many :creators,
           -> { order(position: :asc) },
           as: :resource,
           class_name: 'Authorship',
           dependent: :destroy,
           inverse_of: :resource

  has_one :thumbnail_upload,
          dependent: :destroy,
          as: :resource

  validates :title,
            presence: true

  validates :description,
            presence: true

  validates :published_date,
            edtf_date: true,
            allow_blank: true

  validate :works_are_unique

  accepts_nested_attributes_for :creators,
                                reject_if: :all_blank,
                                allow_destroy: true

  accepts_nested_attributes_for :collection_work_memberships,
                                reject_if: :all_blank,
                                allow_destroy: true
  after_initialize :set_defaults

  after_save :perform_update_index

  after_destroy { SolrDeleteJob.perform_now(uuid) }

  # Fields that can contain multiple values automatically remove blank values
  %i[
    keyword
    contributor
    publisher
    subject
    language
    identifier
    based_near
    related_url
    source
  ].each do |array_field|
    define_method "#{array_field}=" do |vals|
      super(strip_blanks_from_array(vals))
    end
  end

  %i[
    description
    published_date
    subtitle
  ].each do |field|
    define_method "#{field}=" do |val|
      super(val.presence)
    end
  end

  def self.reindex_all(relation: all, async: false)
    relation.find_each do |collection|
      if async
        SolrIndexingJob.perform_later(collection, commit: false)
      else
        SolrIndexingJob.perform_now(collection, commit: false)
      end
    end
    IndexingService.commit
  end

  def build_creator(actor:)
    existing_creator = creators.find { |ca| ca.actor == actor }
    return existing_creator if existing_creator.present?

    creators.build(
      display_name: actor.display_name,
      surname: actor.surname,
      given_name: actor.given_name,
      email: actor.email,
      actor: actor
    )
  end

  def resource_with_doi
    self
  end

  def to_solr
    document_builder.generate(resource: self)
  end

  def update_index(commit: true)
    CollectionIndexer.call(self, commit: commit)
  end

  def indexing_source
    @indexing_source ||= SolrIndexingJob.public_method(:perform_later)
  end

  def work_type
    'collection'
  end

  # TODO Potential Refactoring: #thumbnail_url, #auto_generated_thumbnail_url,
  # TODO and #thumbnail_present? methods here are identical to the methods in Work
  def thumbnail_url
    auto_generated_thumbnail? ? auto_generated_thumbnail_url : uploaded_thumbnail_url.presence
  end

  def auto_generated_thumbnail_url
    auto_generated_thumbnail_urls&.last
  end

  def thumbnail_present?
    uploaded_thumbnail_url.present? || auto_generated_thumbnail_urls.present?
  end

  def empty?
    works
      .select { |work| work.representative_version.published? }
      .empty?
  end

  private

    def uploaded_thumbnail_url
      thumbnail_upload&.file_resource&.thumbnail_url
    end

    def auto_generated_thumbnail_urls
      works.flat_map { |work| work&.latest_published_version&.file_resources }&.map { |fr| fr&.thumbnail_url }&.compact
    end

    def set_defaults
      self.visibility = Permissions::Visibility::OPEN unless access_controls.any?
    end

    def perform_update_index
      indexing_source.call(self)
    end

    def strip_blanks_from_array(arr)
      Array.wrap(arr).reject(&:blank?)
    end

    def document_builder
      SolrDocumentBuilder.new(
        DefaultSchema,
        CreatorSchema,
        PermissionsSchema,
        PublishedDateSchema,
        FacetSchema,
        WorkTypeSchema,
        DoiSchema,
        TitleSchema,
        CollectionSchema
      )
    end

    def works_are_unique
      # Due to Rails weirdness before a Collection is saved to the db,
      # and because we have `has_many :works, through: :collection_work_memberships`
      # we therefore need to check both the `work` and `collection_work_memberships`
      # associations for duplicated work ids
      work_ids = works.map(&:id)
      collection_work_mem_ids = collection_work_memberships.map(&:work_id)

      errors.add(:base, :duplicate_works) if
        work_ids != work_ids.uniq ||
          collection_work_mem_ids != collection_work_mem_ids.uniq
    end
end
