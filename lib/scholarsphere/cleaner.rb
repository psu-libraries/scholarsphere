# frozen_string_literal: true

require 'scholarsphere/solr_admin'

module Scholarsphere
  class Cleaner
    class << self
      def clean
        clean_minio && clean_solr && clean_redis
      end

      def clean_minio
        return unless ENV.key?('S3_ENDPOINT') && verify_aws

        system("aws --endpoint-url #{ENV['S3_ENDPOINT']} s3 rb s3://#{ENV['AWS_BUCKET']} --force")
        system("aws --endpoint-url #{ENV['S3_ENDPOINT']} s3 mb s3://#{ENV['AWS_BUCKET']}")
      end

      def clean_solr
        retries ||= 0
        Blacklight.default_index.connection.delete_by_query('*:*')
        Blacklight.default_index.connection.commit
      rescue StandardError => e
        if (retries += 1) < 5
          sleep 2
          retry
        end
        puts "Solr cleaning failed after 5 attempts: #{e.message}. Attempting to recreate collection."
        SolrAdmin.new.create_collection
      end

      def clean_redis
        redis.keys { |key| redis.del(key) }
      end

      def verify_aws
        return true if aws?

        puts 'WARNING: Install aws in order to delete files from minio'
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
