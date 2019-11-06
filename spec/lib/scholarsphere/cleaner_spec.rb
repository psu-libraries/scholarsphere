# frozen_string_literal: true

require 'scholarsphere/cleaner'
require 'scholarsphere/solr_admin'

RSpec.describe Scholarsphere::Cleaner do
  describe '#clean_minio' do
    context 'when aws is not installed' do
      before { allow(described_class).to receive(:aws?).and_return(false) }

      it 'writes a warnig message to the console' do
        expect { described_class.clean_minio }.to output(/WARNING: Install aws in order to delete files from minio/).to_stdout
      end
    end
  end

  describe '#clean_solr' do
    context 'when there is an RSolr error' do
      let(:admin_spy) { instance_spy(Scholarsphere::SolrAdmin) }

      before do
        allow(Blacklight).to receive(:default_index).and_raise(RuntimeError)
        allow(Scholarsphere::SolrAdmin).to receive(:new).and_return(admin_spy)
      end

      it 'attempts to recreate the solr collection' do
        expect { described_class.clean_solr }.to output(/Solr endpoint not found, attempting to recreate it/).to_stdout
        expect(admin_spy).to have_received(:create_collection)
      end
    end
  end
end
