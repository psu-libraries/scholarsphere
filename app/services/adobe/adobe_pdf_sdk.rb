# frozen_string_literal: true

require_relative 's3_handler'

module Adobe
  class AdobePdfSdk < Base
    include S3Handler

    def initialize(resource)
      super()
      @resource = resource
      @asset_upload_uri_and_asset_id = fetch_upload_uri_and_asset_id
    end

    def adobe_check
      upload_file_to_adobe
      fetch_accessibility_checker_status
      delete_asset
    end

    private

      attr_accessor :resource

      def fetch_upload_uri_and_asset_id
        response = Faraday.post("#{host}/assets") do |req|
          req.headers['Content-Type'] = 'application/json'
          req.headers['Authorization'] = "Bearer #{access_token}"
          req.headers['X-API-Key'] = client_id
          req.body = {
            mediaType: 'application/pdf'
          }.to_json
        end

        if response.success?
          parsed_response = JSON.parse(response.body)
          @upload_uri = parsed_response['uploadUri']
          @asset_id = parsed_response['assetID']
        else
          raise "Failed to get presigned URL: #{response.env.response_body}"
        end
      end

      def upload_uri
        @upload_uri ||= asset_upload_uri_and_asset_id['uploadUri']
      end

      def asset_id
        @asset_id ||= asset_upload_uri_and_asset_id['assetID']
      end

      def upload_file_to_adobe
        file = download_file(resource)
        if file.size > 100000000
          raise 'File size exceeds the limit of 100Mb'
        end

        response = Faraday.put(upload_uri) do |req|
          req.headers['Content-Type'] = 'application/pdf'
          req.body = file.read
        end

        if response.success?
          logger.info 'File uploaded successfully'
        else
          raise "Failed to upload file: #{response.status} - #{response.body}"
        end
      ensure
        file.close
        file.unlink
      end

      def trigger_pdf_accessibility_checker
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
          raise "Failed to run PDF Accessibility Checker: #{response.env.response_body}"
        end
      end

      def polling_location
        @polling_location ||= trigger_pdf_accessibility_checker
      end

      def fetch_accessibility_checker_status
        counter = 0
        parsed_response = {}
        while parsed_response['status'] != 'done' || counter < 60
          response = Faraday.get(polling_location) do |req|
            req.headers['Authorization'] = "Bearer #{access_token}"
            req.headers['X-API-Key'] = client_id
            req.headers['Content-Type'] = 'application/json'
          end

          if response.success?
            parsed_response = JSON.parse(response.body)
            if parsed_response['status'] == 'done'
              store_json_from_presigned_url parsed_response['report']['downloadUri']
              break
            end
          else
            raise "Failed to get Accessibility Checker status: #{response.env.response_body}"
          end
          counter += 1
          sleep 1
        end
      end

      def store_json_from_presigned_url(presigned_url)
        response = Faraday.get(presigned_url)

        if response.success?
          json_response = JSON.parse(response.body)
          logger.info "Accessibility Checker report: #{json_response}"
          # Dump report into model as json-b
        else
          raise "Failed to fetch JSON from presigned URL: #{response.status} - #{response.body}"
        end
      end

      def delete_asset
        response = Faraday.delete("#{host}/assets/#{asset_id}") do |req|
          req.headers['Authorization'] = "Bearer #{access_token}"
          req.headers['X-API-Key'] = client_id
        end

        if response.success?
          logger.info 'Asset deleted successfully'
          nil
        else
          raise "Failed to delete asset: #{respnse.env.response_body}"
        end
      end
  end
end
