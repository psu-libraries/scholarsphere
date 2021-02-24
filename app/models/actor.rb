# frozen_string_literal: true

class Actor < ApplicationRecord
  has_one :user,
          required: false,
          dependent: :restrict_with_exception

  has_many :deposited_works,
           class_name: 'Work',
           foreign_key: 'depositor_id',
           inverse_of: 'depositor',
           dependent: :restrict_with_exception

  has_many :proxy_deposited_works,
           class_name: 'Work',
           foreign_key: 'proxy_id',
           inverse_of: 'proxy_depositor',
           dependent: :restrict_with_exception

  has_many :authorships,
           dependent: :restrict_with_exception,
           inverse_of: :actor

  has_many :created_work_versions,
           through: :authorships,
           source: :resource,
           source_type: 'WorkVersion'

  has_many :created_collections,
           through: :authorships,
           source: :resource,
           source_type: 'Collection'

  has_many :created_works,
           source: :work,
           through: :created_work_versions

  has_many :deposited_collections,
           class_name: 'Collection',
           foreign_key: 'depositor_id',
           inverse_of: 'depositor',
           dependent: :restrict_with_exception

  accepts_nested_attributes_for :user

  validates :surname,
            presence: true,
            unless: -> { validation_context == :from_omniauth }

  validates :psu_id,
            uniqueness: {
              case_sensitive: false,
              allow_nil: true
            }

  validates :psu_id,
            presence: true,
            on: :from_omniauth

  validates :orcid,
            uniqueness: {
              case_sensitive: false,
              allow_nil: true
            },
            format: {
              with: /\A\d{15,15}[0-9X]{1,1}\z/,
              message: 'must be valid',
              allow_nil: true
            }

  validates :orcid,
            presence: true,
            on: :from_user

  after_save :reindex_if_default_alias_changed

  after_destroy :update_index_async

  def default_alias
    super.presence || "#{given_name} #{surname}"
  end

  def update_index_async
    SolrIndexingJob.perform_later(self)
  end

  # This is a little bit different than our other update_index methods. Actors
  # are not themselves directly indexed, but they are faceted upon
  # by Works, Versions, and Collections via the `creators` metadata field.
  # Therefore, if a person updates their `default_alias`, we want to trigger a
  # reindex of those associated items so the updated alias shows up in the facet
  def update_index(_options = {})
    Work.reindex_all(relation: created_works)
    Collection.reindex_all(relation: created_collections)
  end

  # Fields that contain single values automatically remove blank values
  %i[
    surname
    given_name
    email
    orcid
    psu_id
  ].each do |field|
    define_method "#{field}=" do |val|
      super(val.presence)
    end
  end

  private

    def reindex_if_default_alias_changed
      update_index_async if saved_changes.key?(:default_alias)
    end
end
