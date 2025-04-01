# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DestroyWorkVersion, type: :model do
  before do
    allow(IndexingService).to receive(:delete_document)
    allow(WorkIndexer).to receive(:call)
  end

  context 'when the work has more than one version' do
    let(:work) { create(:work, versions_count: 2, has_draft: true) }
    let(:work_version) { work.draft_version }

    it 'deletes only the given work_version' do
      expect {
        described_class.call(work_version)
      }.to change {
        work.versions.count
      }.by(-1)

      expect { work_version.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'returns the parent work reloaded' do
      return_val = described_class.call(work_version)

      expect(return_val).to eq work
      expect(return_val.versions.length).to eq 1
    end

    it 'reindexes solr' do
      described_class.call(work_version)
      expect(IndexingService).to have_received(:delete_document).with(
        work_version.uuid,
        commit: false
      )
      expect(WorkIndexer).to have_received(:call).with(work, commit: true)
    end

    context 'when the given version is published' do
      let(:work) { create(:work, versions_count: 2, has_draft: false) }
      let(:work_version) { work.versions.first }

      context 'when force: false' do
        specify do
          expect {
            described_class.call(work_version, force: false)
          }.to raise_error(ArgumentError)

          expect {
            described_class.call(work_version) # force: false is default
          }.to raise_error(ArgumentError)
        end
      end

      context 'when force: true' do
        it 'deletes the given work version, etc' do
          expect {
            described_class.call(work_version, force: true)
          }.to change {
            work.versions.count
          }.by(-1)

          expect { work_version.reload }.to raise_error(ActiveRecord::RecordNotFound)

          expect(IndexingService).to have_received(:delete_document)
          expect(WorkIndexer).to have_received(:call)
        end
      end
    end
  end

  context 'when the work has only a single version' do
    let(:work) { create(:work, versions_count: 1, has_draft: true) }
    let(:work_version) { work.draft_version }

    it 'deletes the entire work' do
      described_class.call(work_version)
      expect { work_version.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { work.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'returns nil' do
      expect(described_class.call(work_version)).to be_nil
    end

    it 'reindexes solr' do
      described_class.call(work_version)
      expect(IndexingService).to have_received(:delete_document).with(
        work_version.uuid,
        commit: false
      )
      expect(IndexingService).to have_received(:delete_document).with(
        work.uuid,
        commit: true
      )
    end

    context 'when that version is published' do
      let(:work) { create(:work, versions_count: 1, has_draft: false) }
      let(:work_version) { work.latest_version }

      context 'when force: false' do
        specify do
          expect {
            described_class.call(work_version, force: false)
          }.to raise_error(ArgumentError)
        end
      end

      context 'when force: true' do
        it 'deletes the entire work, etc' do
          described_class.call(work_version, force: true)
          expect { work_version.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { work.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect(IndexingService).to have_received(:delete_document).twice
        end
      end

      context "when force: true and the specs aren't artificially loading things from the db weirdly" do
        it 'deletes the entire work, etc' do
          loaded_from_db = WorkVersion.find(work_version.id)
          described_class.call(loaded_from_db, force: true)
          expect { work_version.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { work.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect(IndexingService).to have_received(:delete_document).twice
        end
      end
    end
  end
end
