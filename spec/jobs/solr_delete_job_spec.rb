# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrDeleteJob do
  describe '#perform' do
    before { allow(IndexingService).to receive(:delete_document) }

    it 'calls IndexingService#delete_document' do
      described_class.perform_now('uuid')
      expect(IndexingService).to have_received(:delete_document).with('uuid', commit: true)
    end
  end
end
