# frozen_string_literal: true

class WorkVersion < ApplicationRecord
  include AASM
  include ViewStatistics
  include AllDois
  include GeneratedUuids
  include UpdatingDois

  after_validation :remove_duplicate_errors
  before_save :reset_irrelevant_fields_if_work_type_changed

  fields_with_dois :doi, :identifier

  has_paper_trail

  attr_writer :indexing_source,
              :reload_on_index

  jsonb_accessor :metadata,
                 title: :string,
                 subtitle: :string,
                 version_name: :string,
                 keyword: [:string, array: true, default: []],
                 rights: :string,
                 description: :string,
                 publisher_statement: :string,
                 resource_type: [:string, array: true, default: []],
                 contributor: [:string, array: true, default: []],
                 publisher: [:string, array: true, default: []],
                 published_date: :string,
                 subject: [:string, array: true, default: []],
                 language: [:string, array: true, default: []],
                 identifier: [:string, array: true, default: []],
                 based_near: [:string, array: true, default: []],
                 related_url: [:string, array: true, default: []],
                 source: [:string, array: true, default: []],
                 owner: :string,
                 manufacturer: :string,
                 model: :string,
                 instrument_type: :string,
                 measured_variable: :string,
                 available_date: :string,
                 decommission_date: :string,
                 related_identifier: :string,
                 instrument_resource_type: :string,
                 funding_reference: :string,
                 sub_work_type: :string,
                 program: :string,
                 degree: :string

  belongs_to :work,
             inverse_of: :versions

  belongs_to :external_app,
             optional: true

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
    DEFAULT = 'https://rightsstatements.org/page/InC/1.0/'

    class << self
      def all
        Qa::Authorities::Local::FileBasedAuthority.new(:licenses).all
      end

      def ids
        all.map { |license| license[:id] }
      end

      def ids_for_authorized_visibility
        %w(
          https://rightsstatements.org/page/InC/1.0/
        )
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
            if: :published?,
            unless: :instrument?

  validates :depositor_agreement,
            acceptance: true,
            if: :published?

  validates :psu_community_agreement,
            acceptance: true,
            if: :published?

  validates :accessibility_agreement,
            acceptance: true,
            if: :published?

  validates :sensitive_info_agreement,
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
              message: :format,
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

  # You'll notice this validation is almost identical to the one above. It
  # introduces a tighter set of valid licenses if the work is set to
  # Authorized visibility, and if the optional validation context is used
  validates :rights,
            inclusion: {
              allow_nil: true,
              in: WorkVersion::Licenses.ids_for_authorized_visibility,
              message: :incompatible_license_for_authorized_visibility,
              if: -> { visibility == Permissions::Visibility::AUTHORIZED },
              on: :user_publish
            },
            if: :published?

  validates :published_date,
            presence: true,
            edtf_date: true,
            if: :published?

  validates :decommission_date,
            edtf_date: true,
            if: :published?

  validates :available_date,
            edtf_date: true,
            if: :published?

  validates :description,
            presence: true,
            if: :published?

  validates_with ChangedWorkVersionValidator,
                 if: :published?

  after_commit :perform_update_index, on: [:create, :update]

  attr_accessor :force_destroy

  # Do not allow pubilshed works to be destroyed, unless specially flagged by
  # setting `work_version.force_destroy = true`
  before_destroy do
    prevent_destroy = published? && !force_destroy
    raise ArgumentError, 'cannot delete published versions' if prevent_destroy
  end

  aasm timestamps: true do
    state :draft, intial: true
    state :published, :withdrawn, :removed

    event :publish do
      transitions from: [:draft, :withdrawn],
                  to: :published,
                  after: Proc.new {
                    work.try(:update_deposit_agreement)
                    if work.professional_doctoral_culminating_experience? || work.masters_culminating_experience? || work_type == 'instrument'
                      set_publisher_as_scholarsphere
                    end
                    self.reload_on_index = true
                  }
    end

    event :withdraw do
      after_commit do
        if work.withdrawn?
          WorkRemovedWebhookJob.perform_later(work.uuid)
        end
      end
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
    define_method :"#{array_field}=" do |vals|
      super(strip_blanks_from_array(vals))
    end
  end

  # Fields that contain single values automatically remove blank values
  %i[
    description
    published_date
    publisher_statement
    rights
    subtitle
    version_name
    owner
    manufacturer
    model
    instrument_type
    measured_variable
    available_date
    decommission_date
    related_identifier
    instrument_resource_type
    funding_reference
    sub_work_type
    program
    degree
  ].each do |field|
    define_method :"#{field}=" do |val|
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
      display_name: actor.display_name,
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

  def update_index(commit: true)
    WorkIndexer.call(work, commit: commit, reload: reload_on_index)
  end

  def indexing_source
    @indexing_source ||= SolrIndexingJob.public_method(:perform_later)
  end

  def reload_on_index
    @reload_on_index ||= false
  end

  def update_doi?
    super && latest_published_version?
  end

  def doi_blank?
    work.doi.blank?
  end

  def set_thumbnail_selection
    # work.versions.published.blank? lets us know if the work has just been created
    if work.versions.published.blank? && file_resources.map(&:thumbnail_url).compact.present?
      work.update thumbnail_selection: ThumbnailSelections::AUTO_GENERATED
    end
  end

  def set_publisher_as_scholarsphere
    metadata['publisher'] = ['ScholarSphere']
  end

  def initial_draft?
    version_number == 1 &&
      (draft? || temporarily_published_draft?)
  end

  def submission_link
    "https://scholarsphere.psu.edu/resources/#{uuid}"
  end

  def depositor_access_id
    depositor.psu_id
  end

  def depositor_name
    depositor.display_name
  end

  def form_partial
    self.class.model_name.param_key
  end

  def has_publisher_doi?
    !!identifier.find { |id| Doi.new(id).valid? }
  end

  def needs_accessibility_review
    latest_published_version? && !accessibility_remediation_requested
  end

  def has_image_file_resource?
    file_resources&.any?(&:image?)
  end

  delegate :deposited_at,
           :depositor,
           :embargoed?,
           :embargoed_until,
           :proxy_depositor,
           :visibility,
           :work_type,
           :default_thumbnail?,
           :auto_generated_thumbnail?,
           :thumbnail_url, to: :work

  private

    def reset_irrelevant_fields_if_work_type_changed
      return unless work.will_save_change_to_work_type?

      fields_to_reset = WorkDepositPathway.new(self).fields_to_reset(work.work_type_before_last_save || work.work_type_was)
      fields_to_reset.each do |field|
        send(:"#{field}=", nil)
      end
    end

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
        FacetSchema,
        TitleSchema,
        MemberFilesSchema
      )
    end

    def temporarily_published_draft?
      aasm.from_state == :draft && aasm.to_state == :published
    end

    # when embargoed_until is invalid, it causes a nested error on work.embargoed_until (expected) but when the work version is
    # validated more than once, it causes an identical nested error on work.versions.work.embargoed_until. The suspicion is that
    # this is is a weird edge case in ActiveRecord where we're using two-way nested attributes plus validating multiple times.
    # This method removes the duplicate error before it hits the user. It's not ideal by any means, but it seems to be all we
    # can do until this bug is addressed in Rails.
    def remove_duplicate_errors
      over_limit_errors = []
      errors.errors.each_with_index do |error, index|
        if error.type == :max &&
            [:'work.embargoed_until', :'work.versions.work.embargoed_until'].include?(error.attribute)
          over_limit_errors << index
        end
      end

      if over_limit_errors.length > 1
        errors.errors.delete_at(over_limit_errors[1])
      end
    end

    def instrument?
      WorkDepositPathway.new(self).instrument?
    end
end
