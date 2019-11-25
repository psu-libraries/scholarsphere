# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IndexingService, type: :service do
  before { allow(Blacklight.default_index.connection).to receive(:commit) }

  describe '.add_document' do
    context 'without calling commit' do
      it 'indexes a document into Solr and does NOT commit' do
        described_class.add_document(id: SecureRandom.uuid)
        expect(Blacklight.default_index.connection).not_to have_received(:commit)
      end
    end

    context 'when calling commit' do
      it 'indexes the document into Solr and calls commit' do
        described_class.add_document({ id: SecureRandom.uuid }, commit: true)
        expect(Blacklight.default_index.connection).to have_received(:commit)
      end
    end
  end

  describe '.commit' do
    it 'calls commit on the Solr index' do
      described_class.commit
      expect(Blacklight.default_index.connection).to have_received(:commit)
    end
  end
end
