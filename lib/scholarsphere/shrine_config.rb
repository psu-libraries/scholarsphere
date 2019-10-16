# frozen_string_literal: true

module Scholarsphere
  class ShrineConfig
    PROMOTION_LOCATION = 'store'

    class << self
      def storages
        {
          cache: Shrine::Storage::S3.new(prefix: 'cache', **s3_options),
          PROMOTION_LOCATION.to_sym => Shrine::Storage::S3.new(**s3_options),
          derivatives: Shrine::Storage::S3.new(prefix: 'derivatives', **s3_options)
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
          bucket: ENV['AWS_BUCKET'],
          access_key_id: ENV['AWS_ACCESS_KEY_ID'],
          secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
          region: ENV['AWS_REGION']
        }
      end
    end
  end
end
