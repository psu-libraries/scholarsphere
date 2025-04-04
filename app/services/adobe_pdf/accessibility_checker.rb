# frozen_string_literal: true

module AdobePdf
  # Checks the accessibility of PDF files using Adobe's PDF Services API.
  # It inherits from the Asset class and fetches and stores accessibility reports.
  class AccessibilityChecker < Asset
    class FileSizeExceededError < StandardError; end

    FILE_SIZE_LIMIT = 100_000_000

    def initialize(resource)
      raise FileSizeExceededError, 'File size exceeds the limit of 100Mb' unless valid?(resource)

      super
    end

    def call
      run_operations_on_asset { fetch_accessibility_report }
    end

    private

      def valid?(file_resource)
        file_resource.file_data['metadata']['size'] < FILE_SIZE_LIMIT
      end

      def fetch_accessibility_report
        counter = 0
        while counter < 30
          response = Faraday.get(polling_location) do |req|
            req.headers['Authorization'] = "Bearer #{access_token}"
            req.headers['X-API-Key'] = client_id
            req.headers['Content-Type'] = 'application/json'
          end

          if response.success?
            parsed_response = JSON.parse(response.body)
            if parsed_response['status'] == 'done'
              store_json_from_presigned_url parsed_response['report']['downloadUri']
              return
            end
          else
            raise AdobePdfApiError, "Failed to get Accessibility Checker status: #{response.status} - #{response.body}"
          end
          counter += 1
          sleep 2
        end
        AccessibilityCheckResult.create!(file_resource: resource,
                                         detailed_report: {
                                           error: 'Accessibility check failed: Polling time limit exceeded'
                                         })
      end

      def polling_location
        @polling_location ||= initiate_accessibility_checker
      end

      def initiate_accessibility_checker
        response = Faraday.post("#{host}/operation/accessibilitychecker") do |req|
          req.headers['Authorization'] = "Bearer #{access_token}"
          req.headers['X-API-Key'] = client_id
          req.headers['Content-Type'] = 'application/json'
          req.body = {
            assetID: asset_id
          }.to_json
        end

        if response.success?
          response.env.response_headers['location']
        else
          raise AdobePdfApiError, "Failed to run PDF Accessibility Checker: #{response.status} - #{response.body}"
        end
      end

      def store_json_from_presigned_url(presigned_url)
        response = Faraday.get(presigned_url)

        if response.success?
          json_response = JSON.parse(response.body)
          AccessibilityCheckResult.create!(file_resource: resource,
                                           detailed_report: json_response)
        else
          raise AdobePdfApiError, "Failed to fetch JSON from presigned URL: #{response.status} - #{response.body}"
        end
      end
  end
end
