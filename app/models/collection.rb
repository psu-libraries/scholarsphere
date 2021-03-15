# frozen_string_literal: true

class Collection < ApplicationRecord
  include Permissions
  include DepositedAtTimestamp
  include ViewStatistics

  attr_writer :indexing_source

  jsonb_accessor :metadata,
                 title: :string,
                 subtitle: :string,
                 keyword: [:string, array: true, default: []],
                 description: :string,
                 contributor: [:string, array: true, default: []],
                 publisher: [:string, array: true, default: []],
                 published_date: :string,
                 subject: [:string, array: true, default: []],
                 language: [:string, array: true, default: []],
                 identifier: [:string, array: true, default: []],
                 based_near: [:string, array: true, default: []],
                 related_url: [:string, array: true, default: []],
                 source: [:string, array: true, default: []]

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

  validates :title,
            presence: true

  validates :description,
            presence: true

  validates :published_date,
            edtf_date: true,
            allow_blank: true

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

  def self.reindex_all(relation: all)
    relation.find_each { |collection| CollectionIndexer.call(collection, commit: false) }
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

  # @note Postgres mints uuids, but they are not present until the record is reloaded from the database.  In most cases,
  # this won't present a problem because we only index published versions, and at that point, the version will have
  # already been saved and reloaded from the database. However, there could be edge cases or other unforseen siutations
  # where the uuid is nil and the version needs to be indexed. Reloading it from Postgres will avoid those problems.
  def update_index(commit: true)
    reload if uuid.nil?

    CollectionIndexer.call(self, commit: commit)
  end

  def indexing_source
    @indexing_source ||= SolrIndexingJob.public_method(:perform_later)
  end

  def work_type
    'collection'
  end

  private

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
        WorkTypeSchema
      )
    end
end
