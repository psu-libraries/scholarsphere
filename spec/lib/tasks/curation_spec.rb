# frozen_string_literal: true

require 'rails_helper'

describe 'curation', type: :task do
  describe ':sync' do
    let(:wv1) { build :work_version, :published, work: nil, published_at: 1.day.ago }
    let!(:work1) { create :work, versions: [wv1] }
    let(:wv2) { build :work_version, :published, work: nil, published_at: 5.days.ago }
    let!(:work2) { create :work, versions: [wv2] }
    let(:wv3) { build :work_version, :published, work: nil, published_at: 36.hours.ago }
    let!(:work3) { create :work, versions: [wv3] }
    let(:wv4) { build :work_version, work: nil, published_at: nil }
    let!(:work4) { create :work, versions: [wv4] }
    let!(:work5) { create :work }

    before do
      allow(CurationSyncService).to receive(:sync)
    end

    it 'calls the CurationSyncService' do
      Rake::Task['curation:sync'].invoke
      expect(CurationSyncService).to have_received(:sync).exactly(2).times
    end
  end
end
