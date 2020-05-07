# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionIndexer do
  describe '::call' do
    before { described_class.call(collection) }

    let(:collection) { create(:collection) }

    it 'indexes the collection' do
      expect(SolrDocument.find(collection.uuid)[:title_tesim]).to eq([collection.title])
    end
  end
end
