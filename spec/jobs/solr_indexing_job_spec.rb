# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrIndexingJob, type: :job do
  let(:indexable_resource) { instance_spy('WorkVerison') }

  describe '#perform' do
    it 'delegates to the indexable_resource#update_index method' do
      described_class.perform_now(indexable_resource)
      expect(indexable_resource).to have_received(:update_index)
    end
  end
end
