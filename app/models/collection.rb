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
           inverse_of: :collection

  has_many :creator_aliases,
           class_name: 'CollectionCreation',
           inverse_of: :collection,
           dependent: :destroy

  has_many :creators,
           source: :actor,
           through: :creator_aliases,
           inverse_of: :collections

  accepts_nested_attributes_for :creator_aliases,
                                reject_if: :all_blank,
                                allow_destroy: true
end
