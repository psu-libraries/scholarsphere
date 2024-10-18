# frozen_string_literal: true

module Adobe
  module S3Handler
    def download_file(resource)
      tempfile = Tempfile.new(resource.file_data['id'])
      s3_client.get_object(bucket: aws_bucket,
                           key: "#{resource.file_data['storage']}/#{resource.file_data['id']}",
                           response_target: tempfile.path)
      tempfile.rewind
      tempfile
    end

    private

      def s3_client
        @s3_client ||= Aws::S3::Client.new(
          s3_options
        )
      end

      def aws_bucket
        @aws_bucket ||= ENV.fetch('AWS_BUCKET', nil)
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
