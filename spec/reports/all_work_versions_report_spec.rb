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
      owner
      manufacturer
      model
      instrument_type
      measured_variable
      available_date
      decommission_date
      related_identifier
      instrument_resource_type
      funding_reference
      sub_work_type
      program
      degree
      views
    ] }
  end

  describe '#name' do
    specify { expect(report.name).to eq 'all_work_versions' }
  end

  describe '#rows' do
    # Due to our data model, it's much easier to create Works, then pluck the
    # versions off them, rather that create WorkVersions here
    let!(:published_work) { create(:work, has_draft: false, versions_count: 1) }
    let!(:draft_work) { create(:work, has_draft: true, versions_count: 1) }
    let!(:work_with_two_versions) { create(:work, has_draft: true, versions_count: 2) }

    let(:published_version) { published_work.versions.first }
    let(:draft_version) { draft_work.versions.first }

    before do
      # Add some view statistics
      create(:view_statistic, resource: published_version, count: 5, date: Time.zone.yesterday)
      create(:view_statistic, resource: published_version, count: 1, date: Time.zone.today)

      create(:view_statistic, resource: work_with_two_versions.versions.first, count: 1)
    end

    it 'yields each row to the given block' do
      # Sanity check that factories behaved as expected
      expect(WorkVersion.count).to eq(4)

      yielded_rows = []
      report.rows do |row|
        yielded_rows << row
      end

      # Test ordering by PK
      expect(yielded_rows[0][0]).to eq published_version.uuid
      expect(yielded_rows[1][0]).to eq draft_version.uuid
      expect(yielded_rows[2][0]).to eq work_with_two_versions.versions[0].uuid
      expect(yielded_rows[3][0]).to eq work_with_two_versions.versions[1].uuid

      # Test row for published
      yielded_rows.first.tap do |row|
        version = published_version

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
        expect(row[21]).to eq version.owner
        expect(row[22]).to eq version.manufacturer
        expect(row[23]).to eq version.model
        expect(row[24]).to eq version.instrument_type
        expect(row[25]).to eq version.measured_variable
        expect(row[26]).to eq version.available_date
        expect(row[27]).to eq version.decommission_date
        expect(row[28]).to eq version.related_identifier
        expect(row[29]).to eq version.instrument_resource_type
        expect(row[30]).to eq version.funding_reference
        expect(row[31]).to eq version.sub_work_type
        expect(row[32]).to eq version.program
        expect(row[33]).to eq version.degree
      end

      # Spot check view statistics
      expect(yielded_rows[0][34]).to eq 6
      expect(yielded_rows[1][34]).to eq 0
      expect(yielded_rows[2][34]).to eq 1
      expect(yielded_rows[3][34]).to eq 0
    end
  end
end
