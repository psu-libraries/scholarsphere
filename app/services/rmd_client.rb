# frozen_string_literal: true

class RmdClient
  class RmdClientError < StandardError; end

  def parsed_response
    response = Faraday.new(url: rmd_host).get(endpoint, **faraday_options) do |request|
      request.headers['X-API-Key'] = api_key
    end
    if response.status == 200
      JSON.parse(response.env.response_body)['data']
    else
      message = JSON.parse(response.env.response_body)['message']
      raise RmdClientError, message
    end
  end

  private

    def faraday_options
      # Defined in subclass
    end

    def endpoint
      # Defined in subclass
    end

    def rmd_host
      'https://metadata.libraries.psu.edu'
    end

    def api_key
      ENV.fetch('RMD_API_KEY', 'asdf')
    end
end
