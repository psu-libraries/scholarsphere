# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrIndexingJob do
  let(:indexable_resource) { instance_spy('WorkVerison') }

  describe '#perform' do
    context 'without any arguments' do
      it 'delegates to the indexable_resource#update_index method and commits to Solr' do
        described_class.perform_now(indexable_resource)
        expect(indexable_resource).to have_received(:update_index).with(commit: true)
      end
    end

    context 'when delaying the commit' do
      it 'delegates to the indexable_resource#update_index method and does NOT commit to Solr' do
        described_class.perform_now(indexable_resource, commit: false)
        expect(indexable_resource).to have_received(:update_index).with(commit: false)
      end
    end
  end
end
