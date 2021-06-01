# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkIndexer, :inline_jobs do
  context 'when the work has only one published version' do
    let(:work) { create(:work, has_draft: false) }
    let(:current_published) { work.versions[0] }

    it 'indexes both the work and the published version, marking it as the latest' do
      expect(SolrDocument.find(current_published.uuid)[:latest_version_bsi]).to be(true)
      expect(SolrDocument.find(work.uuid)[:title_tesim]).to eq([current_published.title])
    end
  end

  context 'when the work has only one draft version' do
    let(:work) { create(:work, has_draft: true) }
    let(:draft) { work.versions[0] }

    it 'indexes both the work and the draft version, marking it as the latest' do
      expect(SolrDocument.find(draft.uuid)[:latest_version_bsi]).to be(true)
      expect(SolrDocument.find(work.uuid)[:title_tesim]).to eq([draft.title])
    end
  end

  context 'when the work has a draft and several published versions' do
    let(:work) { create(:work, versions_count: 3, has_draft: true) }
    let(:previous_published) { work.versions[0] }
    let(:current_published) { work.versions[1] }
    let(:draft) { work.versions[2] }

    it 'indexes ALL versions and work, marking the draft as the latest version' do
      expect(SolrDocument.find(current_published.uuid)[:latest_version_bsi]).to be(false)
      expect(SolrDocument.find(previous_published.uuid)[:latest_version_bsi]).to be(false)
      expect(SolrDocument.find(draft.uuid)[:latest_version_bsi]).to be(true)
      expect(SolrDocument.find(work.uuid)[:title_tesim]).to eq([current_published.title])
    end
  end

  context 'when the work is withdrawn' do
    let(:work) { create(:work, has_draft: false) }
    let(:current_published) { work.versions[0] }

    it 'both work and withdrawn version are indexed' do
      expect(SolrDocument.find(work.uuid)[:title_tesim]).to eq([current_published.title])
      current_published.withdraw!
      expect(SolrDocument.find(current_published.uuid)[:latest_version_bsi]).to be(true)
      expect(SolrDocument.find(work.uuid)[:title_tesim]).to eq([current_published.title])
    end
  end
end
