# frozen_string_literal: true

require 'rails_helper'

describe 'curation', type: :task do
  describe ':sync' do
    let(:wv1) { build :work_version, :published, work: nil, sent_for_curation: nil }
    let(:work1) { create :work, versions: [wv1] }

    let(:wv2) { build :work_version, :published, work: nil, sent_for_curation: Time.now }
    let(:work2) { create :work, versions: [wv2] }

    let(:wv4) { build :work_version, work: nil, aasm_state: 'draft' }
    let(:work3) { create :work, versions: [wv4] }

    let(:work4) { create :work }
    let(:service1) { instance_double CurationSyncService }

    before do
      allow(CurationSyncService).to receive(:new).with(work1).and_return(service1)
      allow(service1).to receive(:sync)
    end

    it 'calls the CurationSyncService' do
      Rake::Task['curation:sync'].invoke
      expect(service1).to have_received(:sync).once
    end
  end
end
