# frozen_string_literal: true

class RmdPublication
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
      publication['attributes']
    end

    def publication
      parsed_response['data'].first
    end

    def parsed_response
      response = Faraday.new(url: rmd_host).get(publications_endpoint, doi: doi) do |request|
        request.headers['X-API-Key'] = api_key
      end
      JSON.parse(response.env.response_body)
    end

    def publications_endpoint
      '/v1/publications'
    end

    def rmd_host
      'https://metadata.libraries.psu.edu'
    end

    def api_key
      ENV.fetch('RMD_API_KEY', 'asdf')
    end
end
