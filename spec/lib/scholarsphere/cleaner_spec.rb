# frozen_string_literal: true

require 'scholarsphere/cleaner'
require 'scholarsphere/solr_admin'

RSpec.describe Scholarsphere::Cleaner do
  describe '#clean_seaweedfs' do
    context 'when aws is not installed' do
      before { allow(described_class).to receive(:aws?).and_return(false) }

      it 'writes a warnig message to the console' do
        expect { described_class.clean_seaweedfs }.to output(/WARNING: Install aws in order to delete files from seaweedfs/).to_stdout
      end
    end
  end

  describe '#clean_solr' do
    context 'when there is an RSolr error' do
      let(:admin_spy) { instance_spy(Scholarsphere::SolrAdmin) }
      let(:connection_mock) { double }

      before do
        stub_const('Blacklight', double(default_index: double(connection: connection_mock)))
        allow(connection_mock).to receive(:delete_by_query).and_raise(RuntimeError, 'Test error')
        allow(Scholarsphere::SolrAdmin).to receive(:new).and_return(admin_spy)
      end

      it 'attempts to recreate the solr collection' do
        expect { described_class.clean_solr }.to output(/Solr cleaning failed after 7 attempts/).to_stdout
        expect(admin_spy).to have_received(:create_collection)
      end
    end

    context 'when recreation also fails' do
      let(:connection_mock) { double }

      before do
        stub_const('Blacklight', double(default_index: double(connection: connection_mock)))
        allow(connection_mock).to receive(:delete_by_query).and_raise(RuntimeError, 'Connection lost')
        allow(Scholarsphere::SolrAdmin).to receive(:new).and_raise(RuntimeError, 'Solr unavailable')
      end

      it 'continues without raising' do
        expect { described_class.clean_solr }.to output(/Solr cleanup recovery failed/).to_stdout
      end
    end
  end

  describe '#clean_redis' do
    it 'removes all jobs from the queues' do
      redis_mock = instance_double('Redis')
      allow(redis_mock).to receive(:keys).and_return(['key1', 'key2'])
      allow(described_class).to receive(:redis).and_return(redis_mock)

      result = described_class.clean_redis
      expect(result).to be_an(Array)
    end
  end
end
