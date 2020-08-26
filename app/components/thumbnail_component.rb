# frozen_string_literal: true

class ThumbnailComponent < ApplicationComponent
  attr_reader :resource, :featured

  # @param [SolrDocument, WorkVersion, Collection] resource
  def initialize(resource:, featured: false)
    @resource = resource
    @featured = featured
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
