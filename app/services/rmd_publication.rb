# frozen_string_literal: true

class RmdPublication
  attr_reader :doi

  def initialize(doi)
    @doi = doi
  end

  def to_params
    {
      title: title,
      description: abstract,
      subtitle: secondary_title,
      published_date: published_on,
      keyword: tags.map{|t| t["name"]},
      creators: contributors.each_with_index.map { |c, i| authorship(c, i + 1) },
      publisher: [publisher],
      identifier: [doi],
      related_url: [preferred_open_access_url || supplementary_url]
    }
  end

  private

    def authorship(contributor, position)
      Authorship.new(
        position: position,
        display_name: (contributor["first_name"] + contributor["last_name"]),
        given_name: contributor["first_name"],
        surname: contributor["last_name"],
        email: contributor["psu_user_id"].to_s + '@psu.edu',
        actor: actor(contributor["psu_user_id"].to_s, contributor["first_name"], contributor["last_name"], contributor["psu_user_id"].to_s + '@psu.edu')
      )
    end

    def actor(psu_id, given_name, surname, email)
      return nil if psu_id.blank?

      actor = Actor.find_by(psu_id: psu_id)

      if actor.present?
        actor
      else
        Actor.new(given_name: given_name, email: email, surname: surname, psu_id: psu_id, display_name: (given_name + surname))
      end
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
      attributes['contributors']
    end

    def tags
      attributes['tags']
    end

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
