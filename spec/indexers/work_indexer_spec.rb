# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkIndexer, :inline_jobs do
  describe '::call' do
    before { described_class.call(work) }

    context 'when the work has one published version' do
      let(:work) { create(:work, has_draft: false) }
      let(:current_published) { work.versions[0] }

      it 'indexes the published version and the work' do
        expect(SolrDocument.find(current_published.uuid)[:latest_version_bsi]).to be(true)
        expect(SolrDocument.find(work.uuid)[:title_tesim]).to eq([current_published.title])
      end
    end
  end

  context 'when the work has a draft and several published versions' do
    let(:work) { create(:work, versions_count: 3, has_draft: true) }
    let(:previous_published) { work.versions[0] }
    let(:current_published) { work.versions[1] }
    let(:draft) { work.versions[2] }

    it 'indexes only the published versions and work, marking the latest version' do
      expect(SolrDocument.find(current_published.uuid)[:latest_version_bsi]).to be(true)
      expect(SolrDocument.find(previous_published.uuid)[:latest_version_bsi]).to be(false)
      expect { SolrDocument.find(draft.uuid) }.to raise_error(Blacklight::Exceptions::RecordNotFound)
      expect(SolrDocument.find(work.uuid)[:title_tesim]).to eq([current_published.title])
    end
  end
end
