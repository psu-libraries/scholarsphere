# frozen_string_literal: true

class ThumbnailComponent < ApplicationComponent
  attr_reader :resource, :featured

  # @param [SolrDocument, WorkVersion] resource
  def initialize(resource:, featured: false)
    @resource = resource
    @featured = featured
  end

  def icon
    icon_map.fetch(resource.work_type, 'bar_chart')
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

    # @note Maps a work type with an icon from https://material.io/resources/icons
    def icon_map
      HashWithIndifferentAccess.new({
                                      article: 'article',
                                      audio: 'headset',
                                      book: 'book',
                                      capstone_project: 'landscape',
                                      conference_proceeding: 'groups',
                                      dataset: 'analytics',
                                      dissertation: 'subject',
                                      image: 'image',
                                      journal: 'subject',
                                      map_or_cartographic_material: 'map',
                                      masters_culminating_experience: 'landscape',
                                      masters_thesis: 'subject',
                                      other: 'bar_chart',
                                      # part_of_book: nil,
                                      # poster: nil,
                                      presentation: 'stacked_line_chart',
                                      # project: nil,
                                      report: 'stacked_line_chart',
                                      research_paper: 'biotech',
                                      # software_or_program_code: nil,
                                      thesis: 'subject',
                                      unspecified: 'bar_chart',
                                      video: 'movie'
                                    })
    end
end
