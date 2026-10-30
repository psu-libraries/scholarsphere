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
        # Retry logic for Solr cleanup - Solr 9 can be intermittently unavailable during test runs
        max_attempts = 3
        attempt = 0

        begin
          attempt += 1
          Blacklight.default_index.connection.delete_by_query('*:*')
          Blacklight.default_index.connection.commit
        rescue RSolr::Error::ConnectionRefused, Errno::ECONNREFUSED
          if attempt < max_attempts
            puts "Solr connection refused (attempt #{attempt}/#{max_attempts}), retrying in 2 seconds..."
            sleep 2
            retry
          else
            puts "Solr connection refused after #{max_attempts} attempts, attempting to recreate collection"
            SolrAdmin.new.create_collection
          end
        rescue RuntimeError
          puts 'Solr endpoint not found, attempting to recreate it'
          SolrAdmin.new.create_collection
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
