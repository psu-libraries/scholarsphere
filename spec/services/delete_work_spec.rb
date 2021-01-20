# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeleteWork do
  describe '.call' do
    let!(:work) { create(:work, versions_count: 3, has_draft: true) }

    before { allow(SolrIndexingJob).to receive(:perform_later) }

    specify do
      expect(Work.count).to eq(1)
      expect(WorkVersion.count).to eq(3)
      described_class.call(work.uuid)
      expect(SolrIndexingJob).not_to have_received(:perform_later)
      expect(Work.count).to eq(0)
      expect(WorkVersion.count).to eq(0)
    end
  end
end
