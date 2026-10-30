# frozen_string_literal: true

require 'scholarsphere/solr_admin'

module Scholarsphere
  class Cleaner
    class << self
      def clean
        clean_seaweedfs && clean_solr && clean_redis
      end

      def clean_seaweedfs
        return unless ENV.key?('S3_ENDPOINT') && verify_aws

        system("aws --endpoint-url #{ENV['S3_ENDPOINT']} s3 rb s3://#{ENV['AWS_BUCKET']} --force")
        system("aws --endpoint-url #{ENV['S3_ENDPOINT']} s3 mb s3://#{ENV['AWS_BUCKET']}")
      end

      def clean_solr
        retries ||= 0
        Blacklight.default_index.connection.delete_by_query('*:*')
        Blacklight.default_index.connection.commit
      rescue StandardError => e
        if (retries += 1) < 7
          # Progressive backoff: 2s, 3s, 4s, 5s, 6s, 7s = 27 seconds total
          sleep_time = retries + 1
          puts "Solr unavailable (attempt #{retries}/7), retrying in #{sleep_time} seconds..."
          sleep sleep_time
          retry
        end
        puts "Solr cleaning failed after 7 attempts: #{e.message}. Attempting to recreate collection."
        begin
          SolrAdmin.new.create_collection
        rescue StandardError => cleanup_error
          puts "Solr cleanup recovery failed: #{cleanup_error.message}. Continuing without cleanup."
        end
      end

      def clean_redis
        redis.keys { |key| redis.del(key) }
      end

      def verify_aws
        return true if aws?

        puts 'WARNING: Install aws in order to delete files from seaweedfs'
        false
      end

      def aws?
        system('which aws')
      end

      def redis
        @redis ||= Redis.new(Rails.configuration.redis)
      end
    end
  end
end
