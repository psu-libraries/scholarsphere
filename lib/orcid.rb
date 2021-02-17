# frozen_string_literal: true

require 'faraday'

module Orcid
  class Error < StandardError; end
  class NotFound < StandardError; end

  module Public
    require 'orcid/public/email'
    require 'orcid/public/person'

    class << self
      def get(action:, id:)
        process_response do
          connection.get("#{id}/#{action}") do |req|
            req.headers['Content-Type'] = 'application/json'
          end
        end
      end

      def connection
        Faraday.new(url: ENV.fetch('ORCID_ENDPOINT', 'https://pub.orcid.org/v2.1')) do |conn|
          conn.adapter :net_http
        end
      end

      def process_response
        response = yield
        parsed_body = JSON.parse(response.body)

        raise error_klass(response.status), parsed_body['user-message'] unless response.success?

        parsed_body
      rescue JSON::ParserError
        {}
      end

      def error_klass(status)
        case status
        when 404
          NotFound
        else
          Error
        end
      end
    end
  end
end
