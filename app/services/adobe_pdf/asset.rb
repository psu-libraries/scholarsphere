# frozen_string_literal: true

require_relative 's3_handler'

module AdobePdf
  # The Asset class provides methods for managing assets in Adobe's PDF Services API.
  # It includes methods for uploading, running operations on, and deleting assets.
  class Asset < Base
    include S3Handler

    CONTENT_TYPE_PDF = 'application/pdf'

    # @param resource [FileResource] The FileResource object
    def initialize(resource)
      super()
      @resource = resource
      @asset_upload_uri_and_asset_id = fetch_upload_uri_and_asset_id
    end

    private

      attr_accessor :resource, :asset_upload_uri_and_asset_id

      # Primary method for running operations on an asset.
      # This method uploads the asset to Adobe, yields to the provided block for additional operations,
      # and then deletes the asset.
      # Example:
      #
      #   class MyAsset < AdobePdf::Asset
      #     def perform_operations
      #       run_operations_on_asset do
      #         # Additional operations on the asset
      #         puts "Running additional operations on asset with ID: #{asset_id}"
      #       end
      #     end
      #   end
      #
      #   resource = FileResource.new(file_data: { 'id' => '123', 'storage' => 's3' })
      #   my_asset = MyAsset.new(resource)
      #   my_asset.perform_operations
      #
      # @yield The block to run additional operations on the asset.
      def run_operations_on_asset
        upload_asset_to_adobe
        yield
      rescue StandardError => e
        # Log error in case ensure block fails
        Rails.logger.error e.message
        raise e
      ensure
        # Ensure the asset is always deleted
        delete_asset
      end

      def upload_uri
        @upload_uri ||= asset_upload_uri_and_asset_id['uploadUri']
      end

      def asset_id
        @asset_id ||= asset_upload_uri_and_asset_id['assetID']
      end

      # @return [Hash] Containing the :uploadUri and :assetID.
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
          raise AdobePdfApiError, "Failed to get presigned URL: #{response.status} - #{response.body}"
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
          raise AdobePdfApiError, "Failed to upload file: #{response.status} - #{response.body}"
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
          raise AdobePdfApiError, "Failed to delete asset: #{response.status} - #{response.body}"
        end
      end
  end
end
