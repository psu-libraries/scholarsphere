# frozen_string_literal: true

require 'spec_helper'
require 'webmock'
require 'faraday'
require_relative '../../../lib/scholarsphere/solr_config'
require_relative '../../../lib/scholarsphere/solr_admin'

RSpec.describe Scholarsphere::SolrAdmin do
  subject(:admin) { described_class.new }

  before { WebMock.enable! }

  after { WebMock.disable! }

  let(:config) { Scholarsphere::SolrConfig.new }
  let(:headers) do
    {
      'Accept' => '*/*',
      'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
      'User-Agent' => 'Faraday v0.17.0'
    }
  end

  describe '.reset' do
    let(:stubbed_admin) { instance_spy(described_class) }

    before do
      allow(described_class).to receive(:new).and_return(stubbed_admin)
    end

    it 'deletes everything and recreates the collection' do
      described_class.reset
      expect(stubbed_admin).to have_received(:delete_all_collections)
      expect(stubbed_admin).to have_received(:delete_all_configsets)
      expect(stubbed_admin).to have_received(:upload_config)
      expect(stubbed_admin).to have_received(:create_collection)
    end
  end

  describe '#config' do
    its(:config) { is_expected.to be_a(Scholarsphere::SolrConfig) }
  end

  describe '#zip_file' do
    it 'returns a zip file that we can read' do
      result = admin.zip_file
      contents = result.read
      expect(contents).to be_a(String)
      expect(contents).not_to be_empty
    end
  end

  describe '#configset_exists?' do
    before do
      WebMock.stub_request(
        :get,
        "#{config.config_url}" \
          '?action=LIST' \
      ).with(headers: headers).to_return(status: 200, body: body, headers: {})
    end

    context 'when the config set is present' do
      let(:body) { '{ "configSets": ["_default", "' + config.configset_name + '"] }' }

      it { is_expected.to be_configset_exists }
    end

    context 'when the config set is present' do
      let(:body) { '{ "configSets": ["_default"] }' }

      it { is_expected.not_to be_configset_exists }
    end
  end

  describe '#delete_configset' do
    before do
      WebMock.stub_request(
        :get,
        "#{config.config_url}" \
          '?action=DELETE' \
          '&name=myconfigset'
      ).with(headers: headers).to_return(status: 200, body: '', headers: {})
    end

    it 'deletes a config set' do
      expect(admin.delete_configset('myconfigset')).to be_nil
    end
  end

  describe '#delete_all_configsets' do
    before do
      allow(admin).to receive(:config_sets).and_return(['myconfigset', '_default'])
    end

    it 'deletes all the config sets execpt for the default' do
      expect(admin).to receive(:delete_configset).with('myconfigset')
      admin.delete_all_configsets
    end
  end

  describe '#collection_exists?' do
    before do
      WebMock.stub_request(
        :get,
        "#{config.collection_url}" \
          '?action=LIST' \
      ).with(headers: headers).to_return(status: 200, body: body, headers: {})
    end

    context 'when the collection is present' do
      let(:body) { '{ "collections": ["' + config.collection_name + '"] }' }

      it { is_expected.to be_collection_exists }
    end

    context 'when the collection is NOT present' do
      let(:body) { '{ "collections": ["foo_collection"] }' }

      it { is_expected.not_to be_collection_exists }
    end
  end

  describe '#delete_collection' do
    before do
      WebMock.stub_request(
        :get,
        "#{config.collection_url}" \
          '?action=DELETE' \
          '&name=mycollection'
      ).with(headers: headers).to_return(status: 200, body: '', headers: {})
    end

    it 'deletes a config set' do
      expect(admin.delete_collection('mycollection')).to be_nil
    end
  end

  describe '#delete_all_collections' do
    before do
      allow(admin).to receive(:collections).and_return(['mycollection', 'anothercollection'])
    end

    it 'deletes all the collections' do
      expect(admin).to receive(:delete_collection).with('mycollection')
      expect(admin).to receive(:delete_collection).with('anothercollection')
      admin.delete_all_collections
    end
  end

  describe '#create_collection' do
    before do
      WebMock.stub_request(
        :get,
        "#{config.collection_url}" \
          '?action=CREATE' \
          "&name=#{config.collection_name}" \
          "&numShards=#{config.num_shards}" \
          "&collection.configName=#{config.configset_name}"
      ).with(headers: headers).to_return(status: 200, body: '', headers: {})
    end

    it 'creates a new collection using defaults from ENV' do
      expect(admin.create_collection).to be_nil
    end
  end

  describe '#modify_collection' do
    before do
      WebMock.stub_request(
        :get,
        "#{config.collection_url}" \
          '?action=MODIFYCOLLECTION' \
          "&collection=#{config.collection_name}" \
          "&collection.configName=#{config.configset_name}"
      ).with(headers: headers).to_return(status: 200, body: '', headers: {})
    end

    it 'modifies an existing collection using defaults from ENV' do
      expect(admin.modify_collection).to be_nil
    end
  end

  describe '#upload_config' do
    before do
      WebMock.stub_request(
        :post,
        "#{config.config_url}" \
          '?action=UPLOAD' \
          "&name=#{config.configset_name}"
      ).with(headers: headers).to_return(status: 200, body: '', headers: {})
    end

    it 'uploads a configuration using defaults from ENV' do
      expect(admin.upload_config).to be_nil
    end
  end
end
