# frozen_string_literal: true

module AdobePdf
  # TODO: This whole module can potentially be decoupled from scholarsphere.
  # If the happy path returns the JSON report and everything else raises
  # an error, this code doesn't really need to sit in scholarsphere. File
  # handling is another issue.  Inputs would need to be tweaked to make this
  # work elsewhere, but it would probably be worth doing.
  #
  # The Base class provides common configuration and authentication methods
  # for interacting with Adobe's PDF Services API. It includes methods for
  # retrieving API credentials and generating an access token.
  class Base
    class AdobePdfApiError < StandardError; end

    def initialize
      @logger = Logger.new($stdout)
    end

    private

      attr_accessor :logger

      def client_id
        if Rails.env.test?
          'adobe_client_id'
        else
          ENV.fetch('ADOBE_CLIENT_ID', 'adobe_client_id')
        end
      end

      def client_secret
        if Rails.env.test?
          'adobe_client_secret'
        else
          ENV.fetch('ADOBE_CLIENT_SECRET', 'adobe_client_secret')
        end
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
          raise AdobePdfApiError, "Authentication failed: #{response.status} - #{response.body}"
        end
      end

      # @return [String] the access token
      def access_token
        @access_token ||= fetch_access_token
      end
  end
end
