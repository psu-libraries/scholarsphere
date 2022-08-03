# frozen_string_literal: true

require 'zip'

module Scholarsphere
  class SolrConfig
    CONFIG_PATH = '/solr/admin/configs'
    COLLECTION_PATH = '/solr/admin/collections'

    def solr_username
      ENV.fetch('SOLR_USERNAME', 'scholarsphere')
    end

    def solr_password
      ENV.fetch('SOLR_PASSWORD', 'scholarsphere')
    end

    def solr_host
      ENV.fetch('SOLR_HOST', 'localhost')
    end

    def solr_port
      ENV.fetch('SOLR_PORT', '8983')
    end

    def url
      "http://#{solr_host}:#{solr_port}"
    end

    def config_url
      "#{url}#{CONFIG_PATH}"
    end

    def collection_url
      "#{url}#{COLLECTION_PATH}"
    end

    def query_url
      "http://#{solr_username}:#{CGI.escape(solr_password)}@#{solr_host}:#{solr_port}/solr/#{collection_name}"
    end

    def dir
      ENV.fetch('SOLR_CONFIG_DIR', 'solr/conf')
    end

    def collection_name
      ENV.fetch('SOLR_COLLECTION', 'blacklight-core')
    end

    def num_shards
      ENV.fetch('SOLR_NUM_SHARDS', '1')
    end

    def configset_name
      @configset_name ||= "configset-#{solr_md5}"
    end

    def tempfile
      tmp = Tempfile.new('configset')
      Zip::File.open(tmp, Zip::File::CREATE) do |zipfile|
        Dir["#{dir}/**/**"].each do |file|
          zipfile.add(file.sub("#{dir}/", ''), file)
        end
      end
      tmp
    end

    private

      # Returns a combined MD5 digest for all files in solr config directory
      def solr_md5
        digest = []
        Dir.glob("#{dir}/**/*").each do |f|
          digest.push(Digest::MD5.hexdigest(File.read(f))) if File.file?(f)
        end
        Digest::MD5.hexdigest(digest.join(''))
      end
  end
end
