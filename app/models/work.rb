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
    ARTICLE = 'article'
    AUDIO = 'audio'
    BOOK = 'book'
    CAPSTONE_PROJECT = 'capstone_project'
    CONFERENCE_PROCEEDING = 'conference_proceeding'
    DATASET = 'dataset'
    DISSERTATION = 'dissertation'
    IMAGE = 'image'
    JOURNAL = 'journal'
    MAP_OR_CARTOGRAPHIC_MATERIAL = 'map_or_cartographic_material'
    MASTERS_CULMINATING_EXPERIENCE = 'masters_culminating_experience'
    MASTERS_THESIS = 'masters_thesis'
    OTHER = 'other'
    PART_OF_BOOK = 'part_of_book'
    POSTER = 'poster'
    PRESENTATION = 'presentation'
    PROJECT = 'project'
    REPORT = 'report'
    RESEARCH_PAPER = 'research_paper'
    SOFTWARE_OR_PROGRAM_CODE = 'software_or_program_code'
    VIDEO = 'video'

    def self.all
      [
        ARTICLE,
        AUDIO,
        BOOK,
        CAPSTONE_PROJECT,
        CONFERENCE_PROCEEDING,
        DATASET,
        DISSERTATION,
        IMAGE,
        JOURNAL,
        MAP_OR_CARTOGRAPHIC_MATERIAL,
        MASTERS_CULMINATING_EXPERIENCE,
        MASTERS_THESIS,
        OTHER,
        PART_OF_BOOK,
        POSTER,
        PRESENTATION,
        PROJECT,
        REPORT,
        RESEARCH_PAPER,
        SOFTWARE_OR_PROGRAM_CODE,
        VIDEO
      ]
    end

    def self.default
      DATASET
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

  validates :work_type,
            presence: true,
            inclusion: { in: Types.all }

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

    embargoed_until > DateTime.now
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
