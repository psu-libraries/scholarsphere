# frozen_string_literal: true

class CitationComponent < ApplicationComponent
  attr_reader :work_version, :creators

  def initialize(work_version, deposit_pathway)
    @work_version = work_version
    @deposit_pathway = deposit_pathway
  end

  def render?
    citation_display.present?
  end

  def citation_display
    return unless deposit_pathway.data_and_code? || deposit_pathway.instrument?

    "#{creators_citation_display}(#{year_published}). #{work_version.title} [Data set]. Scholarsphere.#{doi_url}"
  end

  private

    attr_reader :deposit_pathway

    def creators_citation_display
      formatted_creators = ''
      work_version.creators.each_with_index do |creator, index|
        formatted_creators += "#{creator.surname}, #{creator.given_name}"
        formatted_creators += index == work_version.creators.length - 1 ? ' ' : '; '
      end
      formatted_creators
    end

    def doi_url
      work_version.work.doi.blank? ? '' : " https://doi.org/#{work_version.work.doi}"
    end

    def year_published
      Date.edtf(work_version.published_date).try(:year)
    end
end
