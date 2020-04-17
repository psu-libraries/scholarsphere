# frozen_string_literal: true

class WorkVersion < ApplicationRecord
  include AASM
  has_paper_trail

  jsonb_accessor :metadata,
                 title: :string,
                 subtitle: :string,
                 version_name: :string,
                 keyword: [:string, array: true, default: []],
                 rights: :string,
                 description: [:string, array: true, default: []],
                 resource_type: [:string, array: true, default: []],
                 contributor: [:string, array: true, default: []],
                 publisher: [:string, array: true, default: []],
                 published_date: [:string, array: true, default: []],
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

  has_many :creator_aliases,
           class_name: 'WorkVersionCreation',
           inverse_of: :work_version,
           dependent: :destroy

  has_many :creators,
           source: :actor,
           through: :creator_aliases,
           inverse_of: :work_versions

  accepts_nested_attributes_for :file_resources

  accepts_nested_attributes_for :creator_aliases,
                                reject_if: :all_blank,
                                allow_destroy: true

  validates :title,
            presence: true

  validates :file_resources,
            presence: true,
            if: :published?

  validates :creator_aliases,
            presence: true,
            if: :published?

  validates :depositor_agreement,
            acceptance: true,
            if: :published?

  validates :version_number,
            presence: true,
            uniqueness: { scope: :work_id }

  validates :visibility,
            inclusion: {
              in: [Permissions::Visibility::OPEN, Permissions::Visibility::AUTHORIZED],
              message: 'cannot be private'
            },
            if: :published?

  after_save :update_index, if: :published?

  aasm do
    state :draft, intial: true
    state :published, :withdrawn, :removed

    event :publish do
      transitions from: [:draft, :withdrawn], to: :published
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
    description
    resource_type
    contributor
    publisher
    published_date
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

  %i[subtitle version_name rights].each do |field|
    define_method "#{field}=" do |val|
      super(val.presence)
    end
  end

  def build_creator_alias(actor:)
    existing_creator_alias = creator_aliases.detect { |ca| ca.actor == actor }
    return existing_creator_alias if existing_creator_alias.present?

    creator_aliases.build(
      alias: actor.default_alias,
      actor: actor
    )
  end

  def to_solr
    document_builder.generate(resource: self)
  end

  def latest_published_version?
    work.latest_published_version.try(:id) == id
  end

  # @note Postgres mints uuids, but they are not present until the record is reloaded from the database.  In most cases,
  # this won't present a problem because we only index published versions, and at that point, the version will have
  # already been saved and reloaded from the database. However, there could be edge cases or other unforseen siutations
  # where the uuid is nil and the version needs to be indexed. Reloading it from Postgres will avoid those problems.
  def update_index
    reload if uuid.nil?

    WorkIndexer.call(work, commit: true)
  end

  delegate :depositor, :proxy_depositor, :visibility, :embargoed?, to: :work

  private

    def strip_blanks_from_array(arr)
      Array.wrap(arr).reject(&:blank?)
    end

    def document_builder
      SolrDocumentBuilder.new(
        WorkVersionSchema,
        CreatorSchema
      )
    end
end
