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
        max_attempts = 5
        attempt = 0

        begin
          attempt += 1
          Blacklight.default_index.connection.delete_by_query('*:*')
          Blacklight.default_index.connection.commit
        rescue RSolr::Error::ConnectionRefused, Errno::ECONNREFUSED
          if attempt < max_attempts
            sleep_time = 3 * attempt # Exponential backoff: 3s, 6s, 9s, 12s
            puts "Solr connection refused (attempt #{attempt}/#{max_attempts}), retrying in #{sleep_time} seconds..."
            sleep sleep_time
            retry
          else
            puts "Solr connection refused after #{max_attempts} attempts, attempting to recreate collection"
            begin
              SolrAdmin.new.create_collection
            rescue StandardError => e
              puts "Failed to recreate collection after connection refused: #{e.message}"
              # Don't raise - allow test to continue even if cleanup failed
            end
          end
        rescue RuntimeError => e
          puts "Solr runtime error during cleanup: #{e.message}, attempting to recreate collection"
          begin
            SolrAdmin.new.create_collection
          rescue StandardError => retry_error
            puts "Failed to recreate collection: #{retry_error.message}"
            # Don't raise - allow test to continue even if cleanup failed
          end
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
