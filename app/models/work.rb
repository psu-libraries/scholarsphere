# frozen_string_literal: true

class Work < ApplicationRecord
  include Permissions
  include DepositedAtTimestamp
  include AllDois
  include GeneratedUuids
  include ThumbnailSelections

  after_destroy :notify_work_deleted

  fields_with_dois :doi, :latest_published_version_dois

  delegate :email, :display_name, to: :depositor
  delegate :has_publisher_doi?, to: :latest_version

  belongs_to :depositor,
             class_name: 'Actor',
             foreign_key: 'depositor_id',
             inverse_of: 'deposited_works'

  belongs_to :proxy_depositor,
             class_name: 'Actor',
             foreign_key: 'proxy_id',
             inverse_of: 'proxy_deposited_works',
             optional: true

  has_many :curatorships,
           dependent: :destroy

  has_many :curators, through: :curatorships, source: :user

  has_many :versions,
           -> { order(version_number: :asc) },
           class_name: 'WorkVersion',
           inverse_of: 'work',
           dependent: :destroy

  has_many :legacy_identifiers,
           as: :resource,
           dependent: :destroy

  has_many :collection_work_memberships,
           dependent: :destroy

  has_many :collections,
           through: :collection_work_memberships,
           inverse_of: :works

  has_one :thumbnail_upload,
          dependent: :destroy,
          as: :resource

  accepts_nested_attributes_for :versions

  scope :recently_published, -> {
    joins(:versions)
      .where(work_versions: { aasm_state: 'published' })
      .where(work_versions: { sent_for_curation_at: nil })
      .distinct
  }
  validate :embargoed_until_is_valid_date

  module Types
    extend Enumerable

    def self.all
      general.union(scholarly_works)
        .union(data_and_code)
        .union(grad_culminating_experiences)
        .union(instrument)
        .freeze
    end

    def self.each(&)
      all.each(&)
    end

    def self.general
      %w[
        audio
        image
        journal
        map_or_cartographic_material
        other
        poster
        presentation
        project
        unspecified
        video
      ].freeze
    end

    def self.scholarly_works
      %w[
        article
        book
        capstone_project
        conference_proceeding
        dissertation
        masters_thesis
        part_of_book
        report
        research_paper
        thesis
      ].freeze
    end

    def self.data_and_code
      %w[
        dataset
        software_or_program_code
      ].freeze
    end

    def self.instrument
      %w[
        instrument
      ].freeze
    end

    def self.grad_culminating_experiences
      %w[
        masters_culminating_experience
        professional_doctoral_culminating_experience
      ].freeze
    end

    def self.default
      'dataset'
    end

    def self.thesis
      'thesis'
    end

    def self.unspecified
      'unspecified'
    end

    # TODO: Once these have been totally cleaned from the db,
    # we'll no longer need to define them here.
    def self.retired
      %w{
        capstone_project
        dissertation
        masters_thesis
      }
    end

    def self.display(type)
      type.humanize.titleize
    end

    def self.options_for_select_box
      (all - [unspecified, thesis, retired].flatten)
        .sort
        .map { |type| [display(type), type] }
    end
  end

  module DepositAgreement
    CURRENT_VERSION = '2.0'
  end

  enum :work_type, Types.all.zip(Types.all).to_h

  validates :work_type,
            presence: true

  validates :versions,
            presence: true

  def self.build_with_empty_version(*)
    work = new(*)
    work.versions.build if work.versions.empty?
    work.versions.first.version_number = 1
    work
  end

  def self.reindex_all(relation: all, async: false)
    last = relation.count
    count = 0

    relation.find_each do |work|
      if async
        count = count + 1
        SolrIndexingJob.perform_later(work, commit: (count == last))
      else
        work.update_index(commit: false)
      end
    end
    IndexingService.commit unless async
  end

  def update_index(commit: true)
    WorkIndexer.call(self, commit: commit)
  end

  def latest_version
    versions.last
  end

  def latest_published_version
    versions.published.last || NullWorkVersion.new
  end

  def draft_version
    versions.draft.last
  end

  def withdrawn?
    versions.withdrawn.any? && versions.published.none?
  end

  def withdrawn_version
    versions.withdrawn.last
  end

  def representative_version
    if latest_published_version.is_a?(NullWorkVersion)
      withdrawn_version || draft_version
    else
      latest_published_version
    end
  end

  def resource_with_doi
    self
  end

  def to_solr
    document_builder.generate(resource: self)
  end

  def embargoed?
    return false if embargoed_until.blank?

    embargoed_until > Time.zone.now
  end

  def count_view!
    return if latest_published_version.nil?

    latest_published_version.count_view!
  end

  def stats
    @stats ||= AggregateViewStatistics.call(models: versions.published)
  end

  def update_deposit_agreement
    return if deposit_agreement_version == DepositAgreement::CURRENT_VERSION

    update(
      deposit_agreement_version: DepositAgreement::CURRENT_VERSION,
      deposit_agreed_at: Time.zone.now
    )
  end

  # TODO Potential Refactoring: #thumbnail_url, #auto_generated_thumbnail_url,
  # TODO and #thumbnail_present? methods here are identical to the methods in Collection
  def thumbnail_url
    auto_generated_thumbnail? ? auto_generated_thumbnail_url : uploaded_thumbnail_url.presence
  end

  def auto_generated_thumbnail_url
    auto_generated_thumbnail_urls&.last
  end

  def thumbnail_present?
    uploaded_thumbnail_url.present? || auto_generated_thumbnail_urls.present?
  end

  def latest_published_version_dois
    latest_published_version.all_dois
  end

  def current_curator_access_id
    curatorships.order(created_at: :desc)&.first&.access_id
  end

  private

    def uploaded_thumbnail_url
      thumbnail_upload&.file_resource&.thumbnail_url
    end

    def auto_generated_thumbnail_urls
      recent_file_resources = latest_published_version.file_resources
      recent_file_resources.present? ? recent_file_resources.map(&:thumbnail_url).compact : nil
    end

    def document_builder
      SolrDocumentBuilder.new(
        DefaultSchema,
        RepresentativeVersionSchema,
        PermissionsSchema,
        WorkTypeSchema,
        DoiSchema
      )
    end

    def embargoed_until_is_valid_date
      return if embargoed_until.blank?

      unless embargoed_until < (DateTime.now + 4.years)
        errors.add(:embargoed_until, :max)
        nil
      end
    end

    def notify_work_deleted
      WorkRemovedWebhookJob.perform_later(uuid)
    end
end
