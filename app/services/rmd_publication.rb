# frozen_string_literal: true

class RmdPublication
  attr_accessor :doi

  def initialize(doi)
    @doi = doi
  end

  def id
    publication["id"]
  end

  def title
    attributes['title']
  end

  def secondary_title
    attributes['secondary_title']
  end

  def publication_type
    attributes['publication_type']
  end

  def status
    attributes['status']
  end

  def volume
    attributes['volume']
  end

  def issue
    attributes['issue']
  end

  def edition
    attributes['edition']
  end

  def page_range
    attributes['page_range']
  end

  def authors_et_al
    attributes['authors_et_al']
  end

  def abstract
    attributes['abstract']
  end

  def doi
    attributes['doi']
  end

  def preferred_open_access_url
    attributes['preferred_open_access_url']
  end

  def publisher
    attributes['publisher']
  end

  def journal_title
    attributes['journal_title']
  end

  def published_on
    attributes['published_on']
  end

  def supplementary_url
    attributes['supplementary_url']
  end

  def contributors
    attributes['contributors']
  end

  def tags
    attributes['tags']
  end

  private

    def attributes
      publication["attributes"]
    end

    def publication
      parsed_response["data"].first
    end

    def parsed_response
      response = Faraday.new(url: rmd_host).get(publications_endpoint, doi: doi) do |request|
        request.headers["X-API-Key"] = api_key
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
