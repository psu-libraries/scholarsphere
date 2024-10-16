# frozen_string_literal: true

module Adobe
  class AdobePdfSdk
    attr_accessor :resource

    def initialize(resource)
      @resource = resource
      @upload_data = get_upload_uri_and_asset_id
    end

    def adobe_check
      upload_file
      run_pdf_accessibility_checker
      get_accessibility_checker_status
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
          @upload_uri = parsed_response["uploadUri"]
          @asset_id = parsed_response["assetID"]
        else
          error_response = JSON.parse(response.body)['error']
          raise "Failed to get presigned URL: #{error_response['message']}"
        end
      end

      def upload_uri
        @upload_uri ||= upload_data['uploadUri']
      end

      def asset_id
        @asset_id ||= upload_data['assetID']
      end

      def upload_file
        file = download_file
        response = Faraday.put(upload_uri) do |req|
          req.headers['Content-Type'] = 'application/pdf'
          req.body = file.read 
        end

        if response.success?
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
            "assetID": asset_id,
          }.to_json
        end

        if response.success?
          parsed_response = response.status
          puts "PDF Accessibility Checker Report: #{parsed_response}"  # Log the accessibility checker report
          @polling_location = response.env.response_headers['location']
        else
          error_response = response.status
          puts "Error response: #{error_response}"  # Log the error response
          raise "Failed to run PDF Accessibility Checker: #{error_response['message']}"
        end
      end

      def polling_location
        @polling_location
      end

      def get_accessibility_checker_status
        token = access_token
        puts "Getting status for Asset ID: #{asset_id}"  # Log the asset ID
  
        counter = 0
        parsed_response = {}
        while parsed_response["status"] != "done" || counter < 10 do
          response = Faraday.get(polling_location) do |req|
            req.headers['Authorization'] = "Bearer #{token}"
            req.headers['X-API-Key'] = client_id
            req.headers['Content-Type'] = 'application/json'
          end
    
          if response.success?
            parsed_response = JSON.parse(response.body)
            puts "Accessibility Checker Status: #{parsed_response["status"]}"  # Log the status response
            if parsed_response["status"] == "done"
              puts parsed_response["report"]["downloadUri"]
              break
            end
          else
            error_response = JSON.parse(response.body)
            puts "Error response: #{error_response}"  # Log the error response
            raise "Failed to get accessibility checker status: #{error_response['message']}"
          end
          counter += 1
          sleep 1
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
        tempfile = Tempfile.new(resource.file_data['id'])
        s3_client.get_object(bucket: aws_bucket, 
                             key: "#{resource.file_data['storage']}/#{resource.file_data['id']}", 
                             response_target: tempfile.path)
        tempfile.rewind
        tempfile
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
