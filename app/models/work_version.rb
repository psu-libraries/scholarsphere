# frozen_string_literal: true

class WorkVersion < ApplicationRecord
  include AASM

  jsonb_accessor :metadata,
                 title: :string,
                 subtitle: :string,
                 keywords: [:string, array: true, default: []],
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

  accepts_nested_attributes_for :file_resources

  validates :title,
            presence: true

  validates :file_resources,
            presence: true,
            if: :published?

  validates :depositor_agreement,
            acceptance: true,
            if: :published?

  validates :version_number,
            presence: true,
            uniqueness: { scope: :work_id }

  after_save :update_index

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
    keywords
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

  # @note Calls our indexer to add the work version to Solr and commits the results to the index.
  # Newly created records won't have their uuid until they're reloaded from Postgres, which creates the uuids for us.
  def update_index
    reload if uuid.nil?

    IndexingService.call(resource: self, commit: true)
  end

  delegate :depositor, to: :work

  private

    def strip_blanks_from_array(arr)
      Array.wrap(arr).reject(&:blank?)
    end
end
