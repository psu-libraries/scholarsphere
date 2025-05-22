# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserWorksReport do
  subject(:report) {
    described_class.new(
      actor: depositor,
      start_date: Date.parse('2022-02-01'),
      end_date: Date.parse('2022-02-28')
    )
  }

  let(:depositor) { create(:actor) }

  it_behaves_like 'a report' do
    subject { report }
  end

  describe '#new' do
    context 'when given an actor that is not actually an Actor' do
      specify do
        expect { described_class.new(actor: build(:user), start_date: Date.today, end_date: Date.today) }
          .to raise_error(ArgumentError)
      end
    end
  end

  describe '#headers' do
    specify { expect(report.headers).to eq %w[
      work_id
      title
      downloads
      views
    ] }
  end

  describe '#name' do
    it 'includes the depositor, year, and month in question' do
      expect(report.name).to eq "works_#{depositor.psu_id}_2022-02-01_to_2022-02-28"
    end
  end

  describe '#rows' do
    let!(:work_published) { create(:work, has_draft: false, versions_count: 2, depositor: depositor) }
    let!(:work_published_and_draft) { create(:work, has_draft: true, versions_count: 2, depositor: depositor) }
    let!(:other_users_work) { create(:work, has_draft: false, versions_count: 1, depositor: build(:actor)) }
    let!(:work_withdrawn_only) { create(:work, versions: [withdrawn_version], depositor: depositor) }
    let(:withdrawn_version) { build(:work_version, :withdrawn, work: nil) }

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
        .to contain_exactly(work_published.uuid, work_published_and_draft.uuid, work_withdrawn_only.uuid)

      expect(yielded_rows.map { |r| r[0] }).not_to include(other_users_work.uuid)

      work_published_row = yielded_rows.find { |r| r[0] == work_published.uuid }
      work_published_and_draft_row = yielded_rows.find { |r| r[0] == work_published_and_draft.uuid }
      work_withdrawn_only_row = yielded_rows.find { |r| r[0] == work_withdrawn_only.uuid }

      # Test row for without draft
      expect(work_published_row[1]).to eq work_published.latest_published_version.title
      expect(work_published_row[2]).to eq 103 # downloads
      expect(work_published_row[3]).to eq 6

      # Test withdrawn only row
      expect(work_withdrawn_only_row[1]).to be_blank # title should be blank

      # Spot check downloads
      expect(work_published_row[2]).to eq 103
      expect(work_published_and_draft_row[2]).to eq 5

      # Spot check views
      expect(work_published_and_draft_row[3]).to eq 0
    end
  end
end
