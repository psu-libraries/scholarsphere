# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Scholarsphere::SolrAdmin, skip: ci_build? do
  subject(:admin) { described_class.new(config) }

  let(:config) { Scholarsphere::SolrConfig.new }

  before(:all) do
    VCR.configure do |c|
      c.ignore_localhost = false
      c.unignore_host Scholarsphere::SolrConfig.new.solr_host
    end
  end

  after(:all) do
    VCR.configure do |c|
      c.ignore_localhost = true
    end
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
    context 'when the config set is present' do
      it do
        VCR.use_cassette('Scholarsphere_SolrAdmin/config_set_present', erb: { config: config }) do
          expect(admin).to be_configset_exists
        end
      end
    end

    context 'when the config set is NOT present', :vcr do
      it { is_expected.not_to be_configset_exists }
    end
  end

  describe '#delete_configset', :vcr do
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
    context 'when the collection is present' do
      it do
        VCR.use_cassette('Scholarsphere_SolrAdmin/collection_present', erb: { config: config }) do
          expect(admin).to be_collection_exists
        end
      end
    end

    context 'when the collection is NOT present', :vcr do
      it { is_expected.not_to be_collection_exists }
    end
  end

  describe '#delete_collection', :vcr do
    it 'deletes a collection' do
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
    it 'creates a new collection using defaults from ENV' do
      VCR.use_cassette('Scholarsphere_SolrAdmin/create_collection_using_defaults', erb: { config: config }) do
        expect(admin.create_collection).to be_nil
      end
    end
  end

  describe '#modify_collection' do
    it 'modifies an existing collection using defaults from ENV' do
      VCR.use_cassette('Scholarsphere_SolrAdmin/modify_collection_using_defaults', erb: { config: config }) do
        expect(admin.modify_collection).to be_nil
      end
    end
  end

  describe '#upload_config' do
    before { allow(admin).to receive(:raw_data).and_return('zipfile-data') }

    it 'uploads a configuration using defaults from ENV' do
      VCR.use_cassette('Scholarsphere_SolrAdmin/upload_collection_using_defaults', erb: { config: config }) do
        expect(admin.upload_config).to be_nil
      end
    end
  end
end
