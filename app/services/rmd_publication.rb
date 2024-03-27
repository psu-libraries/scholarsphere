# frozen_string_literal: true

class RmdPublication < RmdClient
  class PublicationNotFound < StandardError; end
  attr_reader :doi

  def initialize(doi)
    @doi = doi
  end

  def title
    attributes['title']
  end

  def secondary_title
    attributes['secondary_title']
  end

  def abstract
    attributes['abstract']
  end

  def preferred_open_access_url
    attributes['preferred_open_access_url']
  end

  def publisher
    attributes['publisher']
  end

  def published_on
    attributes['published_on']
  end

  def supplementary_url
    attributes['supplementary_url']
  end

  def contributors
    contributor = Struct.new(:first_name, :middle_name, :last_name, :psu_user_id, :position)
    array = []
    attributes['contributors'].each_with_index do |c, i|
      array << contributor.new(c['first_name'], c['middle_name'], c['last_name'], c['psu_user_id'], i + 1)
    end
    array
  end

  def tags
    attributes['tags'].map { |t| t['name'] }
  end

  private

    def attributes
      @attributes ||= api_response.first.present? ? api_response.first['attributes'] : (raise PublicationNotFound)
    end

    def faraday_options
      { doi: doi }
    end

    def endpoint
      '/v1/publications'
    end
end
