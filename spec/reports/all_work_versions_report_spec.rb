# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AllWorkVersionsReport do
  subject(:report) { described_class.new }

  it_behaves_like 'a report' do
    subject { report }
  end

  describe '#headers' do
    specify { expect(report.headers).to eq %w[id depositor work_type title doi deposited_at deposit_agreed_at embargoed_until visibility latest_published_version downloads views] }
  end

  describe '#name' do
    specify { expect(report.name).to eq 'all_work_versions' }
  end

  describe '#rows' do
    let!(:work_published) { create :work, has_draft: false, versions_count: 2 }
    let!(:work_published_and_draft) { create :work, has_draft: true, versions_count: 2 }
    let!(:work_draft_only) { create :work, has_draft: true, versions_count: 1 }

    before do
      work_published.versions.each do |work_version|
        create :view_statistic, resource: work_version, count: 1
      end

      # Set all versions of the published work to point to the same single file
      version1_file = work_published.latest_published_version.file_resources.first
      work_published.versions.each do |work_version|
        work_version.file_resources = [version1_file]
        work_version.save! 
      end

      # Create view statistics for that single file
      create :view_statistic, resource: version1_file, count: 1
    end

    it 'yields each row to the given block' do
      yielded_rows = []
      report.rows do |row|
        yielded_rows << row
      end

      work_published_row, work_published_and_draft_row, work_draft_only_row = yielded_rows

      # work.uuid,
      # work.depositor.psu_id,
      # work.work_type,
      # latest_version.title,
      # work.doi,
      # work.deposited_at,
      # work.deposit_agreed_at,
      # work.embargoed_until,
      # work.visibility,
      # latest_published_version&.uuid,
      # downloads,
      # views

      # Test ordering by PK
      expect(yielded_rows[0][0]).to eq work_published.uuid
      expect(yielded_rows[1][0]).to eq work_published_and_draft.uuid

      # Test row for without draft
      expect(work_published_row[1]).to eq work_published.depositor.psu_id
      expect(work_published_row[2]).to eq work_published.work_type
      expect(work_published_row[3]).to eq work_published.latest_published_version.title
      expect(work_published_row[4]).to eq work_published.doi
      expect(work_published_row[5]).to eq work_published.deposited_at # TODO: spec the date format (iso8601?)?
      expect(work_published_row[6]).to eq work_published.deposit_agreed_at # TODO spec date format?
      expect(work_published_row[7]).to eq work_published.embargoed_until
      expect(work_published_row[8]).to eq work_published.visibility
      expect(work_published_row[9]).to eq work_published.latest_published_version.uuid

      # Spot check variations on title
      expect(work_published_row[3]).to eq work_published.latest_published_version.title
      expect(work_published_and_draft_row[3]).to eq work_published_and_draft.draft_version.title
      expect(work_draft_only_row[3]).to eq work_draft_only.draft_version.title
      
      # Spot check variations on latest_published_version
      expect(work_published_row[9]).to eq work_published.latest_published_version.uuid
      expect(work_published_and_draft_row[9]).to eq work_published_and_draft.latest_published_version.uuid
      expect(work_draft_only_row[9]).to be_blank

      # Spot check downloads
      expect(work_published_row[10]).to eq 1
      expect(work_published_and_draft_row[10]).to eq 2

      # Spot check view statistics
      expect(work_published_row[11]).to eq 2
    end
  end
end
