# frozen_string_literal: true

module Scholarsphere
  class ShrineConfig
    CACHE_PREFIX = ENV.fetch('SHRINE_CACHE_PREFIX', 'cache')
    PROMOTION_PREFIX = ENV.fetch('SHRINE_PROMOTION_PREFIX', 'store')
    DERIVATIVES_PREFIX = ENV.fetch('SHRINE_DERIVATIVES_PREFIX', 'derivatives')
    THUMBNAILS_PREFIX = ENV.fetch('SHRINE_THUMBNAILS_PREFIX', 'thumbnails')

    class << self
      # @note :cache and :store keys shouldn't be changed because Shrine relies on them heavily; however, we can add
      # additional arbitrary storage locationas as needed.
      def storages
        {
          cache: Shrine::Storage::S3.new(prefix: CACHE_PREFIX, **s3_options),
          store: Shrine::Storage::S3.new(prefix: PROMOTION_PREFIX, **s3_options),
          derivatives: Shrine::Storage::S3.new(prefix: DERIVATIVES_PREFIX, **s3_options),
          thumbnails: Shrine::Storage::S3.new(
            public: true,
            prefix: THUMBNAILS_PREFIX,
            **s3_options.merge(upload_options: { acl: 'public-read' })
          )
        }
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
          bucket: ENV.fetch('AWS_BUCKET', nil),
          access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID', nil),
          secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY', nil),
          region: ENV.fetch('AWS_REGION', nil)
        }
      end
    end
  end
end
