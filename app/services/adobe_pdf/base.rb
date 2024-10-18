# frozen_string_literal: true

module AdobePdf
  class Base
    # The Base class provides common configuration and authentication methods
    # for interacting with Adobe's PDF Services API. It includes methods for
    # retrieving API credentials and generating an access token.
    def initialize
      @logger = Logger.new($stdout)
    end

    private

      attr_accessor :logger

      def client_id
        ENV['ADOBE_CLIENT_ID']
      end

      def client_secret
        ENV['ADOBE_CLIENT_SECRET']
      end

      def host
        'https://pdf-services.adobe.io'
      end

      def oauth_token_path
        '/token'
      end

      # @return [String] the access token
      def fetch_access_token
        response = Faraday.post(host + oauth_token_path) do |req|
          req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
          req.body = {
            client_id: client_id,
            client_secret: client_secret
          }
        end

        if response.success?
          JSON.parse(response.body)['access_token']
        else
          raise "Authentication failed: #{response.env.response_body}"
        end
      end

      # @return [String] the access token
      def access_token
        @access_token ||= fetch_access_token
      end
  end
end
