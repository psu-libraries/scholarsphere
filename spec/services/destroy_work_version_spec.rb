# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DestroyWorkVersion, type: :model do
  context 'when the work has more than one version' do
    let(:work) { create :work, versions_count: 2, has_draft: true }
    let(:work_version) { work.draft_version }

    it 'deletes only the given work_version' do
      expect {
        described_class.call(work_version)
      }.to change {
        work.versions.count
      }.by(-1)

      expect { work_version.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'when the work has only a single version' do
    let(:work) { create :work, versions_count: 1, has_draft: true }
    let(:work_version) { work.draft_version }

    it 'deletes the entire work' do
      described_class.call(work_version)
      expect { work_version.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { work.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
