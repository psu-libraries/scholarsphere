# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AllWorksReport do
  subject(:report) { described_class.new }

  it_behaves_like 'a report' do
    subject { report }
  end

  describe '#headers' do
    specify { expect(report.headers).to eq %w[
      id
      depositor
      work_type
      title
      doi
      deposited_at
      deposit_agreed_at
      embargoed_until
      visibility
      latest_published_version
      downloads
      views
    ] }
  end

  describe '#name' do
    specify { expect(report.name).to eq 'all_works' }
  end

  describe '#rows' do
    let!(:work_published) { create(:work, has_draft: false, versions_count: 2) }
    let!(:work_published_and_draft) { create(:work, has_draft: true, versions_count: 2) }
    let!(:work_draft_only) { create(:work, has_draft: true, versions_count: 1) }
    let!(:work_withdrawn_only) { create(:work, versions: [withdrawn_version]) }
    let(:withdrawn_version) { build(:work_version, :withdrawn, work: nil) }

    before do
      #
      # Create some test data for work views
      #

      # Create some views for every version of a work
      work_published.versions.each do |work_version|
        create(:view_statistic, resource: work_version, count: 1, date: Time.zone.yesterday)
        create(:view_statistic, resource: work_version, count: 1, date: Time.zone.today)
      end

      #
      # Create some test data for file downloads
      #

      # Set all versions of the published work to point to the same single file
      # which more accurately reflects our real production data
      version1_file = work_published.latest_published_version.file_resources.first
      work_published.versions.each do |work_version|
        work_version.file_resources = [version1_file]
        work_version.save!
      end

      # Create downloads (stored as view statistics) for that single file created above
      create(:view_statistic, resource: version1_file, count: 1, date: Time.zone.yesterday)
      create(:view_statistic, resource: version1_file, count: 1, date: Time.zone.today)

      # Make another file on the latest version of the work above
      another_file = create(:file_resource)
      work_published.latest_published_version.file_resources << another_file
      work_published.save!
      create(:view_statistic, resource: another_file, count: 100, date: Time.zone.today)

      # Create a download for another work
      create(:view_statistic,
             resource: work_published_and_draft.latest_published_version.file_resources.first,
             count: 5,
             date: Time.zone.today)
    end

    it 'yields each row to the given block' do
      yielded_rows = []
      report.rows do |row|
        yielded_rows << row
      end

      work_published_row, work_published_and_draft_row, work_draft_only_row, work_withdrawn_only_row = yielded_rows

      # Test ordering by PK
      expect(yielded_rows[0][0]).to eq work_published.uuid
      expect(yielded_rows[1][0]).to eq work_published_and_draft.uuid

      # Test row for without draft
      expect(work_published_row[1]).to eq work_published.depositor.psu_id
      expect(work_published_row[2]).to eq work_published.work_type
      expect(work_published_row[3]).to eq work_published.latest_published_version.title
      expect(work_published_row[4]).to eq work_published.doi
      expect(work_published_row[5]).to be_within(1.second).of(work_published.deposited_at)
      expect(work_published_row[6]).to eq work_published.deposit_agreed_at
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

      # Spot check withdrawn only work
      expect(work_withdrawn_only_row[0]).to eq work_withdrawn_only.uuid
      expect(work_withdrawn_only_row[3]).to be_blank # title should be blank

      # Spot check downloads
      expect(work_published_row[10]).to eq 102
      expect(work_published_and_draft_row[10]).to eq 5

      # Spot check view statistics
      expect(work_published_row[11]).to eq 4
    end
  end
end
