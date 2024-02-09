# spec/airtable_exporter_spec.rb

require 'rails_helper'

RSpec.describe AirtableExporter do
  describe '.call' do
    let(:work_version) { build :work_version,
                         id: 1,
                         uuid: uuid,
                         title: 'Test Submission'
                        }
    let(:depositor) { build(:actor, psu_id: 'abc1234', display_name: 'Test Depositor') }
    let(:work) { build(:work, deposited_at: 'current time', uuid: uuid, deposited_at: deposited_time)}
    let(:deposited_time) { Time.new(2024, 2, 8, 10, 30, 0) }
    let(:uuid) { '8d7eb165-25e0-4b60-8c94-8dc63ae6989f' }

    before do
      allow(WorkVersion).to receive(:find).with(work_version.id).and_return(work_version)
      depositor.deposited_works << [work]
      work.versions << [work_version]
    end
                    
    it 'creates a submission record in Airtable' do
      expect(Submission).to receive(:create).with(
        ID: uuid,
        'Submission Title': 'Test Submission',
        'Submission Link': "https://scholarsphere.psu.edu/resources/#{uuid}",
        'Depositor': 'abc1234',
        'Depositor Name': 'Test Depositor',
        'Deposit Date': deposited_time,
        'Labels': ['Curation Requested']
      )

      AirtableExporter.call(work_version.id)
    end
  end
end
