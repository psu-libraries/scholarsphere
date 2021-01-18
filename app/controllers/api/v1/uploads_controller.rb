# frozen_string_literal: true

module Api::V1
  class UploadsController < RestController
    def create
      render json: {
        url: signer.presigned_url(:put_object, bucket: ENV['AWS_BUCKET'], key: key),
        id: id,
        prefix: prefix
      }
    end

    private

      def signer
        Aws::S3::Presigner.new(
          client: Aws::S3::Client.new(**s3_options)
        )
      end

      def s3_options
        if ENV.key?('S3_ENDPOINT')
          base_options.merge(endpoint: ENV['S3_ENDPOINT'], force_path_style: true)
        else
          base_options
        end
      end

      def base_options
        {
          access_key_id: ENV['AWS_ACCESS_KEY_ID'],
          secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
          region: ENV['AWS_REGION']
        }
      end

      def key
        "#{prefix}/#{id}"
      end

      def prefix
        Scholarsphere::ShrineConfig::CACHE_PREFIX
      end

      def id
        @id ||= "#{SecureRandom.uuid}.#{extension}"
      end

      def extension
        params.require(:extension).gsub('.', '')
      end
  end
end
