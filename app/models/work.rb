# frozen_string_literal: true

class Work < ApplicationRecord
  include Permissions

  belongs_to :depositor,
             class_name: 'Actor',
             foreign_key: 'depositor_id',
             inverse_of: 'deposited_works'

  belongs_to :proxy_depositor,
             class_name: 'Actor',
             foreign_key: 'proxy_id',
             inverse_of: 'proxy_deposited_works',
             optional: true

  has_many :versions,
           -> { order(created_at: :asc) },
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

  accepts_nested_attributes_for :versions

  module Types
    def self.all
      %w[
        article
        audio
        book
        capstone_project
        conference_proceeding
        dataset
        dissertation
        image
        journal
        map_or_cartographic_material
        masters_culminating_experience
        masters_thesis
        other
        part_of_book
        poster
        presentation
        project
        report
        research_paper
        software_or_program_code
        video
      ].freeze
    end

    def self.default
      'dataset'
    end

    def self.display(type)
      type.humanize.titleize
    end

    def self.options_for_select_box
      all
        .sort
        .map { |type| [display(type), type] }
    end
  end

  enum work_type: Types.all.zip(Types.all).to_h

  validates :work_type,
            presence: true

  validates :versions,
            presence: true

  def self.build_with_empty_version(*args)
    work = new(*args)
    work.versions.build if work.versions.empty?
    work.versions.first.version_number = 1
    work
  end

  def self.reindex_all
    find_each { |work| WorkIndexer.call(work, commit: false) }
    IndexingService.commit
  end

  def latest_version
    versions.last
  end

  def latest_published_version
    versions.published.last
  end

  def draft_version
    versions.draft.last
  end

  def to_solr
    document_builder.generate(resource: self)
  end

  def embargoed?
    return false if embargoed_until.blank?

    embargoed_until > Time.zone.now
  end

  private

    def document_builder
      SolrDocumentBuilder.new(
        DefaultSchema,
        LatestPublishedVersionSchema,
        PermissionsSchema,
        WorkTypeSchema
      )
    end
end
