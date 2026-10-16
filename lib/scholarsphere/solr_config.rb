# frozen_string_literal: true

require 'zip'
require 'cgi'

module Scholarsphere
  class SolrConfig
    CONFIG_PATH = '/solr/admin/configs'
    COLLECTION_PATH = '/solr/admin/collections'

    def solr_username
      ENV.fetch('SOLR_USERNAME', nil)
    end

    def solr_password
      ENV.fetch('SOLR_PASSWORD', nil)
    end

    def solr_protocol
      ENV.fetch('SOLR_PROTOCOL', 'http')
    end

    def solr_host
      ENV.fetch('SOLR_HOST', 'localhost')
    end

    def solr_port
      ENV.fetch('SOLR_PORT', '8983')
    end

    def url
      port = solr_port.to_s.empty? ? '' : ":#{solr_port}"
      "#{solr_protocol}://#{solr_host}#{port}"
    end

    def config_url
      "#{url}#{CONFIG_PATH}"
    end

    def collection_url
      "#{url}#{COLLECTION_PATH}"
    end

    def query_url
      base_url = "#{url}/solr/#{collection_name}"
      if solr_username && solr_password
        auth = "#{solr_username}:#{CGI.escape(solr_password)}"
        return base_url.gsub('://', "://#{auth}@")
      end
      base_url
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
      Zip::File.open(tmp, create: true) do |zipfile|
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
          if File.file?(f)
            File.open(f) { |file| digest.push(Digest::MD5.hexdigest(file.read)) }
          end
        end
        Digest::MD5.hexdigest(digest.join(''))
      end
  end
end
