# frozen_string_literal: true

require 'zip'

class SolrConfigurator
  def initialize
    connection
  end

  def zip_file
    File.open(tempfile)
  end

  def configset_exists?
    resp = @connection.get('/solr/admin/configs?action=LIST&omitHeader=true')
    JSON.parse(resp.body)['configSets'].include?(configset_name)
  end

  def collection_exists?
    resp = @connection.get('/solr/admin/collections?action=LIST')
    JSON.parse(resp.body)['collections'].include?(collection_name)
  end

  def create_collection
    if collection_exists?
      return true
    end

    resp = @connection.get("/solr/admin/collections?action=CREATE&name=#{collection_name}&numShards=#{num_shards}")
    check_resp(resp)
  end

  def modify_collection
    puts 'Modifying Collection to use Configset'
    uri = %W(
      /solr/admin/collections
      ?action=MODIFYCOLLECTION
      &collection=#{collection_name}
      &collection.configName=#{@configset_name}
    ).join
    resp = @connection.get(uri)
    check_resp(resp)
  end

  def upload_config
    if configset_exists?
      puts "Configset #{configset_name} already exists. Skipping Upload"
      return true
    end
    puts "Uploading #{configset_name}"
    resp = @connection.post do |req|
      req.url "/solr/admin/configs?action=UPLOAD&name=#{configset_name}"
      req.headers['Content-Type'] = 'octect/stream'
      req.body = raw_data
    end
    puts 'Finished uploading...'
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
    # This can be better! PRs accepted.
    def check_resp(resp)
      if resp.status == 200
        true
      else
        puts resp.body
        exit(1) # rubocop:disable Rails/Exit
      end
    end

    def tempfile
      tmp = Tempfile.new('configset')
      puts "Zipping up files in #{solr_config_dir}"
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
        # faraday.response :logger
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
      ENV.fetch('SOLR_COLLECTION', 'scholarsphere')
    end

    def num_shards
      ENV.fetch('SOLR_NUM_SHARDS', '1')
    end
end
