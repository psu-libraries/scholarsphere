# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AllWorkVersionsReport do
  subject(:report) { described_class.new }

  it_behaves_like 'a report' do
    subject { report }
  end

  describe '#headers' do
    specify { expect(report.headers).to eq %w[
      id
      work_id
      state
      version_number
      title
      subtitle
      version_name
      keyword
      rights
      description
      publisher_statement
      resource_type
      contributor
      publisher
      published_date
      subject
      language
      identifier
      based_near
      related_url
      source
      views
    ] }
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
    end

    it 'yields each row to the given block' do
      yielded_rows = []
      report.rows do |row|
        yielded_rows << row
      end

      # Test ordering by PK
      expect(yielded_rows[0][0]).to eq work_published.versions[0].uuid
      expect(yielded_rows[1][0]).to eq work_published.versions[1].uuid

      # Test row for published
      yielded_rows.first.tap do |row|
        version = work_published.versions.first

        expect(row[0]).to eq version.uuid
        expect(row[1]).to eq version.work.uuid
        expect(row[2]).to eq version.aasm_state
        expect(row[3]).to eq version.version_number
        expect(row[4]).to eq version.title
        expect(row[5]).to eq version.subtitle
        expect(row[6]).to eq version.version_name
        expect(row[7]).to eq version.keyword
        expect(row[8]).to eq version.rights
        expect(row[9]).to eq version.description
        expect(row[10]).to eq version.publisher_statement
        expect(row[11]).to eq version.resource_type
        expect(row[12]).to eq version.contributor
        expect(row[13]).to eq version.publisher
        expect(row[14]).to eq version.published_date
        expect(row[15]).to eq version.subject
        expect(row[16]).to eq version.language
        expect(row[17]).to eq version.identifier
        expect(row[18]).to eq version.based_near
        expect(row[19]).to eq version.related_url
        expect(row[20]).to eq version.source
      end

      # Spot check view statistics
      expect(yielded_rows[0][21]).to eq 1
      expect(yielded_rows[1][21]).to eq 1
    end
  end
end
