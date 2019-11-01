# frozen_string_literal: true

module Scholarsphere
  class Cleaner
    class << self
      def clean
        clean_minio && clean_solr
      end

      def clean_minio
        return unless ENV.key?('S3_ENDPOINT') && verify_aws

        system("aws --endpoint-url #{ENV['S3_ENDPOINT']} s3 rb s3://#{ENV['AWS_BUCKET']} --force")
        system("aws --endpoint-url #{ENV['S3_ENDPOINT']} s3 mb s3://#{ENV['AWS_BUCKET']}")
      end

      def clean_solr
        Blacklight.default_index.connection.delete_by_query('*:*')
        Blacklight.default_index.connection.commit
      end

      def verify_aws
        return true if aws?

        puts 'WARNING: Install aws in order to delete files from minio'
        false
      end

      def aws?
        system('which aws')
      end
    end
  end
end
