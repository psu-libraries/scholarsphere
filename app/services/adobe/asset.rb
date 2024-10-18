# frozen_string_literal: true

require_relative 's3_handler'

module Adobe
  class Asset < Base
    include S3Handler

    class FileSizeExceededError < StandardError; end

    CONTENT_TYPE_PDF = 'application/pdf'

    def initialize(resource)
      super()
      @resource = resource
      @asset_upload_uri_and_asset_id = fetch_upload_uri_and_asset_id
    end

    private

      attr_accessor :resource, :asset_upload_uri_and_asset_id

      def run_operation_on_asset
        upload_asset_to_adobe
        yield
        delete_asset
      end

      def upload_uri
        @upload_uri ||= asset_upload_uri_and_asset_id['uploadUri']
      end

      def asset_id
        @asset_id ||= asset_upload_uri_and_asset_id['assetID']
      end

      def fetch_upload_uri_and_asset_id
        response = Faraday.post("#{host}/assets") do |req|
          req.headers['Content-Type'] = 'application/json'
          req.headers['Authorization'] = "Bearer #{access_token}"
          req.headers['X-API-Key'] = client_id
          req.body = {
            mediaType: CONTENT_TYPE_PDF
          }.to_json
        end

        if response.success?
          JSON.parse(response.body)
        else
          raise "Failed to get presigned URL: #{response.env.response_body}"
        end
      end

      def upload_asset_to_adobe
        file = download_file(resource)

        response = Faraday.put(upload_uri) do |req|
          req.headers['Content-Type'] = CONTENT_TYPE_PDF
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
