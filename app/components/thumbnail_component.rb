# frozen_string_literal: true

class ThumbnailComponent < ApplicationComponent
  attr_reader :resource, :featured

  # @param [SolrDocument, WorkVersion, Collection] resource
  def initialize(resource:, featured: false)
    @resource = resource
    @featured = featured
  end

  def thumbnail_url
    file_resources.present? ? file_resources.last.file_derivatives[:thumbnail]&.url : nil
  end

  def icon
    icon_map.fetch(icon_key, 'bar_chart')
  end

  def html_classes
    if featured?
      'thumbnail col-xxl-6 ft-work__img'
    else
      'thumbnail'
    end
  end

  private

    def file_resources
      work.latest_published_version.file_resources
    end

    def work
      resource.is_a?(Collection) ? resource.works.first.work : solr_doc_to_work(resource)
    end

    def solr_doc_to_work(solr_doc)
      solr_doc["model_ssi"] == 'Collection' ? Collection.find_by(uuid: solr_doc.id).works.first : Work.find(resource.work_id)
    end

    def featured?
      @featured != false
    end

    def icon_key
      resource.try(:work_type)
    end

    # @note Maps a work type or class with an icon from https://material.io/resources/icons
    def icon_map
      HashWithIndifferentAccess.new({
                                      # part_of_book: nil,
                                      # poster: nil,
                                      # project: nil,
                                      # software_or_program_code: nil,
                                      article: 'article',
                                      audio: 'headset',
                                      book: 'book',
                                      capstone_project: 'landscape',
                                      collection: 'view_carousel',
                                      conference_proceeding: 'groups',
                                      dataset: 'analytics',
                                      dissertation: 'subject',
                                      image: 'image',
                                      journal: 'subject',
                                      map_or_cartographic_material: 'map',
                                      masters_culminating_experience: 'landscape',
                                      masters_thesis: 'subject',
                                      other: 'bar_chart',
                                      presentation: 'stacked_line_chart',
                                      report: 'stacked_line_chart',
                                      research_paper: 'biotech',
                                      thesis: 'subject',
                                      unspecified: 'bar_chart',
                                      video: 'movie'
                                    })
    end
end
