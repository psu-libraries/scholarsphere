# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MonthlyWorksReport do
  subject(:report) { described_class.new(date: Date.parse('2022-02-16')) }

  it_behaves_like 'a report' do
    subject { report }
  end

  describe '#headers' do
    specify { expect(report.headers).to eq %w[
      work_id
      month
      year
      downloads
      views
    ] }
  end

  describe '#name' do
    it 'includes the year and month in question' do
      expect(report.name).to eq 'monthly_works_2022-02'
    end
  end

  describe '#rows' do
    let!(:work_published) { create(:work, has_draft: false, versions_count: 2) }
    let!(:work_published_and_draft) { create(:work, has_draft: true, versions_count: 2) }
    let!(:work_draft_only) { create(:work, has_draft: true, versions_count: 1) }

    before do
      #
      # Create some test data for work views
      #

      # Create some views for every version of a work
      work_published.versions.each do |work_version|
        create(:view_statistic, resource: work_version, count: 1, date: Date.parse('2022-02-01'))
        create(:view_statistic, resource: work_version, count: 1, date: Date.parse('2022-02-16'))
        create(:view_statistic, resource: work_version, count: 1, date: Date.parse('2022-02-28'))

        # Should not be included in the counts
        create(:view_statistic, resource: work_version, count: 1, date: Date.parse('2022-01-31'))
        create(:view_statistic, resource: work_version, count: 1, date: Date.parse('2022-03-01'))
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
      create(:view_statistic, resource: version1_file, count: 1, date: Date.parse('2022-02-01'))
      create(:view_statistic, resource: version1_file, count: 1, date: Date.parse('2022-02-16'))
      create(:view_statistic, resource: version1_file, count: 1, date: Date.parse('2022-02-28'))

      # Should not be included in the counts
      create(:view_statistic, resource: version1_file, count: 1, date: Date.parse('2022-01-31'))
      create(:view_statistic, resource: version1_file, count: 1, date: Date.parse('2022-03-01'))

      # Make another file on the latest version of the work above
      another_file = create(:file_resource)
      work_published.latest_published_version.file_resources << another_file
      work_published.save!
      create(:view_statistic, resource: another_file, count: 100, date: Date.parse('2022-02-16'))

      # Create a download for another work
      create(:view_statistic,
             resource: work_published_and_draft.latest_published_version.file_resources.first,
             count: 5,
             date: Date.parse('2022-02-16'))
    end

    it 'yields each row to the given block' do
      yielded_rows = []
      report.rows do |row|
        yielded_rows << row
      end

      # Test that it generates one row for each work
      # Note that order is not guaranteed with `find_each` or `find_in_batches`
      expect(yielded_rows.map { |r| r[0] })
        .to contain_exactly(work_published.uuid, work_published_and_draft.uuid, work_draft_only.uuid)

      work_published_row = yielded_rows.find { |r| r[0] == work_published.uuid }
      work_published_and_draft_row = yielded_rows.find { |r| r[0] == work_published_and_draft.uuid }

      # Test row for without draft
      expect(work_published_row[1]).to eq '2'
      expect(work_published_row[2]).to eq '2022'
      expect(work_published_row[3]).to eq 103 # downloads
      expect(work_published_row[4]).to eq 6

      # Spot check downloads
      expect(work_published_row[3]).to eq 103
      expect(work_published_and_draft_row[3]).to eq 5

      # Spot check views
      expect(work_published_and_draft_row[4]).to eq 0
    end
  end
end
