# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IndexingService, type: :service do
  def index_count
    Blacklight.default_index.connection.get('select', params: { q: '*:*' })['response']['numFound']
  end

  describe '.add_document' do
    context 'without calling commit' do
      it 'indexes a document into Solr and does NOT commit' do
        expect {
          described_class.add_document({ id: SecureRandom.uuid })
        }.not_to(change { index_count })
      end
    end

    context 'when calling commit' do
      it 'indexes the document into Solr' do
        expect {
          described_class.add_document({ id: SecureRandom.uuid }, commit: true)
        }.to change { index_count }.by(1)
      end
    end
  end

  describe '.delete_document' do
    let(:id) { SecureRandom.uuid }

    before { described_class.add_document({ id: id }, commit: true) }

    context 'without calling commit' do
      it 'removes the document from the index and does NOT commit' do
        expect {
          described_class.delete_document({ id: id })
        }.not_to(change { index_count })
      end
    end

    context 'when calling commit' do
      it 'removes the document from Solr' do
        expect {
          described_class.delete_document({ id: id }, commit: true)
        }.to change { index_count }.by(-1)
      end
    end
  end

  describe '.commit' do
    it 'calls Blacklight.default_index.connection' do
      allow(Blacklight.default_index.connection).to receive(:commit)
      described_class.commit
      expect(Blacklight.default_index.connection).to have_received(:commit)
    end
  end
end
