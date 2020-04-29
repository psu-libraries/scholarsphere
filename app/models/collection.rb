# frozen_string_literal: true

class Collection < ApplicationRecord
  jsonb_accessor :metadata,
                 title: :string,
                 subtitle: :string,
                 keyword: [:string, array: true, default: []],
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

  accepts_nested_attributes_for :creator_aliases,
                                reject_if: :all_blank,
                                allow_destroy: true

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

  %i[subtitle].each do |field|
    define_method "#{field}=" do |val|
      super(val.presence)
    end
  end

  def build_creator_alias(actor:)
    existing_creator_alias = creator_aliases.find { |ca| ca.actor == actor }
    return existing_creator_alias if existing_creator_alias.present?

    creator_aliases.build(
      alias: actor.default_alias,
      actor: actor
    )
  end

  private

    def strip_blanks_from_array(arr)
      Array.wrap(arr).reject(&:blank?)
    end
end
