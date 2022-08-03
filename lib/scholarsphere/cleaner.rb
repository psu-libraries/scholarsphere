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

        system("aws --endpoint-url #{ENV.fetch('S3_ENDPOINT', nil)} s3 rb s3://#{ENV.fetch('AWS_BUCKET', nil)} --force")
        system("aws --endpoint-url #{ENV.fetch('S3_ENDPOINT', nil)} s3 mb s3://#{ENV.fetch('AWS_BUCKET', nil)}")
      end

      def clean_solr
        Blacklight.default_index.connection.delete_by_query('*:*')
        Blacklight.default_index.connection.commit
      rescue RuntimeError
        puts 'Solr endpoint not found, attempting to recreate it'
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
