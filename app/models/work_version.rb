# frozen_string_literal: true

class WorkVersion < ApplicationRecord
  include AASM
  include ViewStatistics
  has_paper_trail

  attr_writer :indexing_source

  jsonb_accessor :metadata,
                 title: :string,
                 subtitle: :string,
                 version_name: :string,
                 keyword: [:string, array: true, default: []],
                 rights: :string,
                 description: :string,
                 resource_type: [:string, array: true, default: []],
                 contributor: [:string, array: true, default: []],
                 publisher: [:string, array: true, default: []],
                 published_date: :string,
                 subject: [:string, array: true, default: []],
                 language: [:string, array: true, default: []],
                 identifier: [:string, array: true, default: []],
                 based_near: [:string, array: true, default: []],
                 related_url: [:string, array: true, default: []],
                 source: [:string, array: true, default: []]

  belongs_to :work,
             inverse_of: :versions

  has_many :file_version_memberships,
           dependent: :destroy

  has_many :file_resources,
           through: :file_version_memberships

  has_many :creators,
           -> { order(position: :asc) },
           as: :resource,
           class_name: 'Authorship',
           dependent: :destroy,
           inverse_of: :resource

  accepts_nested_attributes_for :work

  accepts_nested_attributes_for :file_resources

  accepts_nested_attributes_for :creators,
                                reject_if: :all_blank,
                                allow_destroy: true

  module Licenses
    # @note This is when we are unable to determine a license. It should not be used as a default option for the user.
    DEFAULT = 'http://www.europeana.eu/portal/rights/rr-r.html'

    class << self
      def all
        Qa::Authorities::Local::FileBasedAuthority.new(:licenses).all
      end

      def ids
        all.map { |license| license[:id] }
      end

      def active
        all.map.select do |license|
          license[:active] == true
        end
      end

      def options_for_select_box
        active
          .map { |license| [license[:label], license[:id]] }
      end

      def label(id)
        all
          .select { |license| license[:id] == id }
          .map { |license| license[:label] }
          .first
      end
    end
  end

  validates :title,
            presence: true

  validates :file_resources,
            presence: true,
            if: :published?

  validates :creators,
            presence: true,
            if: :published?

  validates :depositor_agreement,
            acceptance: true,
            if: :published?

  validates :version_number,
            presence: true,
            uniqueness: { scope: :work_id }

  # @note The regex comes from https://semver.org/
  validates :version_name,
            allow_nil: true,
            format: {
              with: /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$/, # rubocop:disable Layout/LineLength
              message: 'Version names must be in semantic version format, ex. 1.0.0',
              multiline: true
            }

  validates :visibility,
            inclusion: {
              in: [Permissions::Visibility::OPEN, Permissions::Visibility::AUTHORIZED],
              message: 'cannot be private'
            },
            if: :published?

  validates :rights,
            presence: true,
            inclusion: {
              in: WorkVersion::Licenses.ids,
              allow_nil: true # Avoid duplicating the above presence validation
            },
            if: :published?

  validates :published_date,
            presence: true,
            edtf_date: true,
            if: :published?,
            unless: -> { validation_context == :migration_api }

  validates :description,
            presence: true,
            if: :published?,
            unless: -> { validation_context == :migration_api }

  after_save :perform_update_index

  before_destroy do
    raise ArgumentError, 'cannot delete published versions' if published?
  end

  aasm do
    state :draft, intial: true
    state :published, :withdrawn, :removed

    event :publish do
      transitions from: [:draft, :withdrawn], to: :published, after: Proc.new { work.try(:update_deposit_agreement) }
    end

    event :withdraw do
      transitions from: :published, to: :withdrawn
    end

    event :remove do
      transitions from: [:draft, :withdrawn], to: :removed
    end
  end

  # Fields that can contain multiple values automatically remove blank values
  %i[
    keyword
    resource_type
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

  # Fields that contain single values automatically remove blank values
  %i[
    description
    published_date
    rights
    subtitle
    version_name
  ].each do |field|
    define_method "#{field}=" do |val|
      super(val.presence)
    end
  end

  def self.build_with_empty_work(attributes = {}, depositor:)
    work_version = new(attributes)
    work_version.version_number = 1
    work_version.build_work if work_version.work.blank?
    work_version.work.depositor = depositor
    work_version.work.versions = [work_version]
    work_version.work.visibility = Permissions::Visibility::OPEN
    work_version
  end

  def build_creator(actor:)
    existing_creator = creators.find { |ca| ca.actor == actor }
    return existing_creator if existing_creator.present?

    creators.build(
      display_name: actor.default_alias,
      surname: actor.surname,
      given_name: actor.given_name,
      email: actor.email,
      actor: actor
    )
  end

  def resource_with_doi
    work
  end

  def to_solr
    document_builder.generate(resource: self)
  end

  def latest_published_version?
    work.latest_published_version.try(:id) == id
  end

  def latest_version?
    work.latest_version.try(:id) == id
  end

  # @note Postgres mints uuids, but they are not present until the record is reloaded from the database.  In most cases,
  # this won't present a problem because we only index published versions, and at that point, the version will have
  # already been saved and reloaded from the database. However, there could be edge cases or other unforseen siutations
  # where the uuid is nil and the version needs to be indexed. Reloading it from Postgres will avoid those problems.
  def update_index(commit: true)
    reload if uuid.nil?

    WorkIndexer.call(work, commit: commit)
  end

  def indexing_source
    @indexing_source ||= SolrIndexingJob.public_method(:perform_later)
  end

  delegate :depositor, :proxy_depositor, :visibility, :embargoed?, :work_type, :deposited_at, to: :work

  private

    def perform_update_index
      indexing_source.call(self)
    end

    def strip_blanks_from_array(arr)
      Array.wrap(arr).reject(&:blank?)
    end

    def document_builder
      SolrDocumentBuilder.new(
        WorkVersionSchema,
        WorkTypeSchema,
        CreatorSchema,
        PublishedDateSchema,
        FacetSchema
      )
    end
end
