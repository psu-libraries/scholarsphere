# frozen_string_literal: true

require 'zip'

class SolrConfigurator
  def initialize; end

  def zip_file
    File.open(tempfile)
  end

  def configset_exists?
    resp = connection.get('/solr/admin/configs',
                          action: 'LIST')
    JSON.parse(resp.body)['configSets'].include?(configset_name)
  end

  def collection_exists?
    resp = connection.get('/solr/admin/collections',
                          action: 'LIST')
    JSON.parse(resp.body)['collections'].include?(collection_name)
  end

  def create_collection
    resp = connection.get('/solr/admin/collections',
                          action: 'CREATE',
                          name: collection_name,
                          numShards: num_shards)
    check_resp(resp)
  end

  def modify_collection
    resp = connection.get('/solr/admin/collections',
                          action: 'MODIFYCOLLECTION',
                          collection: collection_name,
                          "collection.configName": configset_name)
    check_resp(resp)
  end

  def upload_config
    resp = connection.post('/solr/admin/configs') do |req|
      req.params = { "action": 'UPLOAD', "name": configset_name }
      req.headers['Content-Type'] = 'octect/stream'
      req.body = raw_data
    end
    check_resp(resp)
  end

  private

    # Returns a combined MD5 digest for all files in solr config directory
    def solr_md5
      digest = []
      Dir.glob("#{solr_config_dir}/**/*").each do |f|
        digest.push(Digest::MD5.hexdigest(File.open(f).read)) if File.file?(f)
      end
      Digest::MD5.hexdigest(digest.join(''))
    end

    def configset_name
      md5 = solr_md5
      @configset_name ||= "#{collection_name}-#{md5}"
    end

    def raw_data
      @raw_data ||= zip_file.read
    end

    # Gets a response object, if it's status code is not 200, we emit the body and bail
    def check_resp(resp)
      raise resp.body unless resp.status == 200
    end

    def tempfile
      tmp = Tempfile.new('configset')
      Zip::File.open(tmp, Zip::File::CREATE) do |zipfile|
        Dir["#{solr_config_dir}/**/**"].each do |file|
          zipfile.add(file.sub("#{solr_config_dir}/", ''), file)
        end
      end
      tmp
    end

    def connection
      @connection ||= Faraday.new("http://#{solr_host}:#{solr_port}") do |faraday|
        faraday.request :multipart
        faraday.adapter :net_http
      end
    end

    def solr_host
      ENV.fetch('SOLR_HOST', 'localhost')
    end

    def solr_port
      ENV.fetch('SOLR_PORT', '8983')
    end

    def solr_config_dir
      ENV.fetch('SOLR_CONFIG_DIR', 'solr/conf')
    end

    def collection_name
      ENV.fetch('SOLR_COLLECTION', 'blacklight-core')
    end

    def num_shards
      ENV.fetch('SOLR_NUM_SHARDS', '1')
    end
end
