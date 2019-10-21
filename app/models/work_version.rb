# frozen_string_literal: true

class WorkVersion < ApplicationRecord
  include AASM

  jsonb_accessor :metadata,
                 title: :string,
                 subtitle: :string,
                 keywords: [:string, array: true, default: []],
                 rights: :string,
                 description: :string,
                 resource_type: :string,
                 contributor: :string,
                 publisher: :string,
                 published_date: :string,
                 subject: :string,
                 language: :string,
                 identifier: :string,
                 based_near: :string,
                 related_url: :string,
                 source: :string

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
  [:keywords].each do |array_field|
    define_method "#{array_field}=" do |vals|
      super(strip_blanks_from_array(vals))
    end
  end

  delegate :depositor, to: :work

  private

    def strip_blanks_from_array(arr)
      Array.wrap(arr).reject(&:blank?)
    end

    # @note Calls our indexer to add the work version to Solr. Newly created records won't have their uuid until they're
    # reloaded from Postgres, which creates the uuids for us.
    def update_index
      reload if uuid.nil?

      IndexingService.call(resource: self, schema: default_schema)
    end

    # @todo This is basic schema until we flesh one out that's more robust.
    def default_schema
      {
        title_tesi: ['title'],
        subtitle_tesi: ['subtitle'],
        keywords_tesim: ['keywords'],
        rights_tesi: ['rights'],
        description_tesi: ['description'],
        resource_type_tesi: ['resource_type'],
        contributor_tesi: ['contributor'],
        publisher_tesi: ['publisher'],
        published_date_tesi: ['published_date'],
        subject_tesi: ['subject'],
        language_tesi: ['language'],
        identifier_tesi: ['identifier'],
        based_near_tesi: ['based_near'],
        related_url_tesi: ['related_url'],
        source_tesi: ['source']
      }
    end
end
