# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CurationTaskClient do
  describe '.send_curation' do
    let(:work_version) { build :work_version,
                               id: 1,
                               uuid: uuid,
                               title: 'Test Submission'
    }
    let(:depositor) { build(:actor, psu_id: 'abc1234', display_name: 'Test Depositor') }
    let(:work) { build(:work, uuid: uuid, deposited_at: deposited_time, embargoed_until: embargo) }
    let(:deposited_time) { Time.new(2024, 2, 8, 10, 30, 0) }
    let(:uuid) { '8d7eb165-25e0-4b60-8c94-8dc63ae6989f' }
    let(:expected_record) {
      {ID: uuid,
      'Submission Title': 'Test Submission',
      'Submission Link': "https://scholarsphere.psu.edu/resources/#{uuid}",
      Depositor: 'abc1234',
      'Depositor Name': 'Test Depositor',
      'Deposit Date': deposited_time,
      Labels: labels}
    }

    before do
      allow(WorkVersion).to receive(:find).with(work_version.id).and_return(work_version)
      depositor.deposited_works << [work]
      work.versions << [work_version]
    end

    context 'when the work is not embargoed' do
      let(:embargo) { nil }
      let(:labels) { ['Curation Requested']}

      it 'creates a submission record in Airtable' do
        expect(Submission).to receive(:create).with(expected_record)

        described_class.send_curation(work_version.id, requested: true)
      end
    end

    context 'when the work is embargoed' do
      let(:embargo) { 3.years.from_now }
      let(:labels) { ['Curation Requested', 'Embargoed']}

      it 'creates a submission record in Airtable' do
        expect(Submission).to receive(:create).with(expected_record)

        described_class.send_curation(work_version.id, requested: true)
      end
    end

    context 'when curation was not requested' do
      let(:embargo) { nil }
      let(:labels) { []}

      it 'creates a submission record in Airtable' do
        expect(Submission).to receive(:create).with(expected_record)

        described_class.send_curation(work_version.id)
      end
    end

    context 'when a previous version is found in Airtable' do
      let(:embargo) { nil }
      let(:labels) { ['Updated Version'] }

      it 'creates a submission record in Airtable' do
        expect(Submission).to receive(:create).with(expected_record)

        described_class.send_curation(work_version.id, updated_version: true)
      end
    end
  end

  describe '.find' do
    it 'finds a record if it is in Airtable' do
      expect(Submission).to receive(:all).with(filter: "{ID} = 'testID'")

      described_class.find('testID')
    end
  end

  describe '.find_all' do
    let!(:work) { create(:work, versions_count: 2) }
    let(:task1) { instance_double 'Submission',
      fields: { 'ID' => work.versions.first.uuid },
      id: 'table_id_1'}
    let(:task2) { instance_double 'Submission',
        fields: { 'ID' => work.versions.second.uuid },
        id: 'table_id_1'}

    before do
      allow(Submission).to receive(:all).with(filter: "{ID} = '#{work.versions.first.uuid}'").and_return([task1])
      allow(Submission).to receive(:all).with(filter: "{ID} = '#{work.versions.second.uuid}'").and_return([task2])
    end

    it 'finds a record if it is in Airtable' do
      expect(Submission).to receive(:all).twice

      described_class.find_all(work.id)
    end
  end
end
