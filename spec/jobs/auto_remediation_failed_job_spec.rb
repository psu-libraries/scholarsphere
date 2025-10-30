# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AutoRemediationFailedJob do
  describe '#perform' do
    let(:existing_job_uuid) { SecureRandom.uuid }
    let!(:file_resource) do
      create(:file_resource,
             remediation_job_uuid: existing_job_uuid,
             work_versions: [create(:work_version)])
    end
    let(:work) { file_resource.work_versions.first.work }
    let(:service) do
      instance_double(LibanswersApiService,
                      admin_create_ticket: 'https://psu.libanswers.com/fake-ticket')
    end

    before do
      allow(LibanswersApiService).to receive(:new).and_return(service)
    end

    context 'when the file resource with the given remediation_job_uuid exists' do
      it 'creates a LibAnswers ticket' do
        described_class.perform_now(existing_job_uuid)

        expect(LibanswersApiService).to have_received(:new)
        expect(service).to have_received(:admin_create_ticket).with(work.id, 'work_remediation_failed')
      end
    end

    context 'when the file resource with the given remediation_job_uuid does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          described_class.perform_now('nonexistent-uuid')
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
