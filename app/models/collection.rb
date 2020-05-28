# frozen_string_literal: true

class Collection < ApplicationRecord
  include Permissions

  jsonb_accessor :metadata,
                 title: :string,
                 subtitle: :string,
                 keyword: [:string, array: true, default: []],
                 description: [:string, array: true, default: []],
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

  # Beware that the order clause here references the join table. You may need to
  # account for that in your `includes` or `eager_load` statements
  has_many :works,
           -> { order('collection_work_memberships.position ASC') },
           through: :collection_work_memberships,
           inverse_of: :collections

  has_many :creator_aliases,
           class_name: 'CollectionCreation',
           inverse_of: :collection,
           dependent: :destroy

  has_many :creators,
           source: :actor,
           through: :creator_aliases,
           inverse_of: :collections

  validates :title,
            presence: true

  validates :published_date,
            edtf_date: true,
            allow_blank: true,
            unless: -> { validation_context == :migration_api }

  accepts_nested_attributes_for :creator_aliases,
                                reject_if: :all_blank,
                                allow_destroy: true

  after_initialize :set_defaults

  after_save :update_index

  # Fields that can contain multiple values automatically remove blank values
  %i[
    keyword
    description
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
    published_date
    subtitle
  ].each do |field|
    define_method "#{field}=" do |val|
      super(val.presence)
    end
  end

  def self.reindex_all
    find_each { |collection| CollectionIndexer.call(collection, commit: false) }
    IndexingService.commit
  end

  def build_creator_alias(actor:)
    existing_creator_alias = creator_aliases.find { |ca| ca.actor == actor }
    return existing_creator_alias if existing_creator_alias.present?

    creator_aliases.build(
      alias: actor.default_alias,
      actor: actor
    )
  end

  def to_solr
    document_builder.generate(resource: self)
  end

  # @note Postgres mints uuids, but they are not present until the record is reloaded from the database.  In most cases,
  # this won't present a problem because we only index published versions, and at that point, the version will have
  # already been saved and reloaded from the database. However, there could be edge cases or other unforseen siutations
  # where the uuid is nil and the version needs to be indexed. Reloading it from Postgres will avoid those problems.
  def update_index
    reload if uuid.nil?

    CollectionIndexer.call(self, commit: true)
  end

  private

    def set_defaults
      self.visibility = Permissions::Visibility::OPEN unless access_controls.any?
    end

    def strip_blanks_from_array(arr)
      Array.wrap(arr).reject(&:blank?)
    end

    def document_builder
      SolrDocumentBuilder.new(
        DefaultSchema,
        CreatorSchema,
        PermissionsSchema
      )
    end
end
