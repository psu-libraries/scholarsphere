# frozen_string_literal: true

module Api::V1
  class UploadsController < RestController
    # @return [String] json response sent to the client
    # @note The content_md5 parameter is required because we always want our clients to include an md5 checksum of the
    # files they are sending.
    def create
      render json: {
        url: signer.presigned_url(:put_object, bucket: ENV.fetch('AWS_BUCKET', nil), key: key,
                                               content_md5: content_md5),
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
          access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID', nil),
          secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY', nil),
          region: ENV.fetch('AWS_REGION', nil)
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

      def content_md5
        params.require(:content_md5)
      end
  end
end
