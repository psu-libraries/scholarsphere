# frozen_string_literal: true

module Adobe
  class AdobePdfSdk
    attr_accessor :resource

    def initialize(resource)
      @resource = resource
    end

    def adobe_check
      upload_file
      run_pdf_accessibility_checker
    end

    private

      def get_access_token
        response = Faraday.post(host + oauth_token_path) do |req|
          req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
          req.body = {
            client_id: client_id,
            client_secret: client_secret
          }
        end

        if response.success?
          access_token = JSON.parse(response.body)["access_token"]
          access_token
        else
          error_response = JSON.parse(response.body)['error']
          raise "Authentication failed: #{error_response['message']}"
        end
      end

      def access_token
        @access_token ||= get_access_token
      end

      def get_upload_uri_and_asset_id
        token = access_token
        response = Faraday.post(host + '/assets') do |req|
          req.headers['Content-Type'] = 'application/json'
          req.headers['Authorization'] = "Bearer #{token}"
          req.headers['X-API-Key'] = client_id
          req.body = {
            mediaType: "application/pdf"
        }.to_json
        end

        if response.success?
          parsed_response = JSON.parse(response.body)
          puts "Asset info: #{parsed_response}"
          parsed_response
        else
          error_response = JSON.parse(response.body)['error']
          raise "Failed to get presigned URL: #{error_response['message']}"
        end
      end

      def upload_uri
        @upload_uri ||= get_upload_uri_and_asset_id["uploadUri"]
      end

      def asset_id
        @asset_id ||= get_upload_uri_and_asset_id["assetID"]
      end

      def upload_file
        file = download_file
        response = Faraday.put(upload_uri) do |req|
          req.headers['Content-Type'] = 'application/pdf'
          req.body = file.read
        end

        if response.success?
          byebug
          puts "File uploaded successfully"
        else
          raise "Failed to upload file: #{response.status} - #{response.body}"
        end
      ensure
        file.close
        file.unlink 
      end

      def run_pdf_accessibility_checker
        token = access_token
        puts "Running PDF Accessibility Checker for Asset ID: #{asset_id}"  # Log the asset ID
        response = Faraday.post("#{host}/operation/accessibilitychecker") do |req|
          req.headers['Authorization'] = "Bearer #{token}"
          req.headers['X-API-Key'] = client_id
          req.headers['Content-Type'] = 'application/json'
          req.body = {
            assetID: asset_id,
          }.to_json
        end

        if response.success?
          parsed_response = JSON.parse(response.body)
          puts "PDF Accessibility Checker Report: #{parsed_response}"  # Log the accessibility checker report
          parsed_response
        else
          error_response = JSON.parse(response.body)
          puts "Error response: #{error_response}"  # Log the error response
          raise "Failed to run PDF Accessibility Checker: #{error_response['message']}"
        end
      end

      def client_id
        ENV['ADOBE_CLIENT_ID']
      end

      def client_secret
        ENV['ADOBE_CLIENT_SECRET']
      end

      def host
        "https://pdf-services.adobe.io"
      end

      def oauth_token_path
        "/token"
      end

      def s3_client
        @s3_client ||= Aws::S3::Client.new(
          base_options 
        )
      end

      def aws_bucket
        @aws_bucket ||= ENV.fetch('AWS_BUCKET', nil)
      end

      def download_file
        file = Tempfile.new(resource.file_data['id'], binmode: true)
        s3_client.get_object(bucket: aws_bucket, 
                             key: "#{resource.file_data['storage']}/#{resource.file_data['id']}", 
                             response_target: file.path)
        file.rewind 
        file
      end

      def base_options
        {
          access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID', nil),
          secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY', nil),
          region: ENV.fetch('AWS_REGION', 'us-east-1'),
          endpoint: "http://127.0.0.1:9000",
          force_path_style: true
        }#.merge(endpoint: ENV['S3_ENDPOINT'], force_path_style: true)
      end
    end
end
