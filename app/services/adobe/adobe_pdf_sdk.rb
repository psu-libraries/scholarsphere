# frozen_string_literal: true

module Adobe
  class AdobePdfSdk
    attr_accessor :resource

    def initialize(resource)
      @resource = resource
      @asset_upload_uri_and_asset_id = fetch_upload_uri_and_asset_id
    end

    def adobe_check
      upload_file
      fetch_accessibility_checker_status
      delete_asset
    end

    private

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
          error_response = JSON.parse(response.body)['error']
          raise "Authentication failed: #{response.env.response_body}"
        end
      end

      def access_token
        @access_token ||= fetch_access_token
      end

      def fetch_upload_uri_and_asset_id
        token = access_token
        response = Faraday.post("#{host}/assets") do |req|
          req.headers['Content-Type'] = 'application/json'
          req.headers['Authorization'] = "Bearer #{token}"
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

      def upload_file
        file = download_file
        if file.size > 100000000
          raise 'File size exceeds the limit of 100Mb'
        end

        response = Faraday.put(upload_uri) do |req|
          req.headers['Content-Type'] = 'application/pdf'
          req.body = file.read
        end

        if response.success?
          Rails.logger.info 'File uploaded successfully'
        else
          raise "Failed to upload file: #{response.status} - #{response.body}"
        end
      ensure
        file.close
        file.unlink
      end

      def trigger_pdf_accessibility_checker
        token = access_token
        response = Faraday.post("#{host}/operation/accessibilitychecker") do |req|
          req.headers['Authorization'] = "Bearer #{token}"
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
        token = access_token

        counter = 0
        parsed_response = {}
        while parsed_response['status'] != 'done' || counter < 60
          response = Faraday.get(polling_location) do |req|
            req.headers['Authorization'] = "Bearer #{token}"
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
          Rails.logger.info "Accessibility Checker report: #{json_response}"
          # Dump report into model as json-b
        else
          raise "Failed to fetch JSON from presigned URL: #{response.status} - #{response.body}"
        end
      end

      def delete_asset
        token = access_token

        response = Faraday.delete("#{host}/assets/#{asset_id}") do |req|
          req.headers['Authorization'] = "Bearer #{token}"
          req.headers['X-API-Key'] = client_id
        end

        if response.success?
          Rails.logger.info 'Asset deleted successfully'
          nil
        else
          raise "Failed to delete asset: #{respnse.env.response_body}"
        end
      end

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

      def s3_client
        @s3_client ||= Aws::S3::Client.new(
          s3_options
        )
      end

      def aws_bucket
        @aws_bucket ||= ENV.fetch('AWS_BUCKET', nil)
      end

      def download_file
        tempfile = Tempfile.new(resource.file_data['id'])
        s3_client.get_object(bucket: aws_bucket,
                             key: "#{resource.file_data['storage']}/#{resource.file_data['id']}",
                             response_target: tempfile.path)
        tempfile.rewind
        tempfile
      end

      def s3_options
        options = {
          access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID', nil),
          secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY', nil),
          region: ENV.fetch('AWS_REGION', 'us-east-1')
        }

        options = options.merge(endpoint: ENV['S3_ENDPOINT'], force_path_style: true) if ENV.key?('S3_ENDPOINT')
        options
      end
  end
end
