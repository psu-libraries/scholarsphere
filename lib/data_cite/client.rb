# frozen_string_literal: true

require 'faraday'

module DataCite
  class Client
    class Error < StandardError; end

    def initialize(prefix: nil, publisher: nil)
      @prefix = prefix
      @publisher = publisher
    end

    def register(suffix = nil)
      attributes = if suffix.present?
                     { doi: "#{prefix}/#{suffix}" }
                   else
                     { prefix: prefix }
                   end

      data = {
        type: 'dois',
        attributes: attributes
      }

      process_response post(data: data)
    end

    def publish(doi: nil, metadata:)
      data = {
        type: 'dois',
        attributes: metadata.merge(
          event: 'publish',
          publisher: publisher
        )
      }

      if doi.blank?
        data[:attributes][:prefix] = prefix
        process_response post(data: data)
      else
        data[:id] = doi
        process_response put(doi: doi, data: data)
      end
    end

    def update(doi:, metadata:)
      data = {
        type: 'dois',
        id: doi,
        attributes: metadata
      }

      process_response put(doi: doi, data: data)
    end

    def get(doi:)
      process_response connection.get("/dois/#{doi}")
    end

    def search(params)
      process_body connection.get('/dois', **params.merge('client-id' => username))
    end

    def delete(doi:)
      process_response connection.delete("/dois/#{doi}")
    end

    def prefix
      @prefix ||= ENV.fetch('DATACITE_PREFIX', '10.33532')
    end

    def publisher
      @publisher ||= ENV.fetch('DATACITE_PUBLISHER', 'scholarsphere')
    end

    private

      def post(data:)
        connection.post do |req|
          req.headers['Content-Type'] = 'application/vnd.api+json'
          req.body = { data: data }.to_json
        end
      end

      def put(doi:, data:)
        connection.put("/dois/#{doi}") do |req|
          req.headers['Content-Type'] = 'application/vnd.api+json'
          req.body = { data: data }.to_json
        end
      end

      def process_response(response)
        parsed_body = process_body(response)
        doi = parsed_body.dig('data', 'id')

        [doi, parsed_body]
      end

      def process_body(response)
        parsed_body = begin
                        JSON.parse(response.body)
                      rescue JSON::ParserError
                        {}
                      end

        return parsed_body if response.success?

        # @todo Consider raising more specific errors, i.e.
        # MethodNotAllowedError under certain cases
        errors = parsed_body.fetch('errors', [])
        stringified_errors = errors.inspect
        message = stringified_errors.presence || "DataCite response returned #{response.status}"

        raise Error.new(message)
      end

      def connection
        @connection ||= Faraday.new(url: endpoint) do |conn|
          conn.request :basic_auth, username, password
          conn.adapter :net_http
        end
      end

      def endpoint
        @endpoint ||= ENV.fetch('DATACITE_ENDPOINT', 'https://api.test.datacite.org/dois')
      end

      def username
        @username ||= ENV.fetch('DATACITE_USERNAME', 'psu.ss-dev')
      end

      def password
        @password ||= ENV['DATACITE_PASSWORD']
      end
  end
end
