# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BuildAutoRemediatedWorkVersionJob do
  let(:file_resource) { create(:file_resource, remediation_job_uuid: existing_job_uuid) }
  let(:existing_job_uuid) { SecureRandom.uuid }
  let(:remediated_file_url) { 'https://example.com/remediated.pdf' }
  let(:unpublished_work_version) {create(:work_version) }
  let(:published_work_version) { create(:work_version, :published) }
  let(:lib_answers) { LibanswersApiService.new }

  describe '#perform' do
    before do
      allow(lib_answers).to receive(:admin_create_ticket)
      allow(BuildAutoRemediatedWorkVersion).to receive(:call)
      allow(LibanswersApiService).to receive(:new).and_return(lib_answers)
    end

    context 'when the file resource with the given remediation_job_uuid does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          described_class.perform_now('nonexistent-uuid', remediated_file_url)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the file resource with the given remediation_job_uuid exists' do
      it 'calls the service when perform_now is used' do
        described_class.perform_now(file_resource.remediation_job_uuid, remediated_file_url)
        expect(BuildAutoRemediatedWorkVersion).to have_received(:call).with(file_resource, remediated_file_url)
      end
    end

    context 'when the service returns a published new work version' do
      before do
        allow(BuildAutoRemediatedWorkVersion).to receive(:call).and_return(published_work_version)
      end
      it 'calls the LibanswersApiService with a remediation ticket' do
        described_class.perform_now(file_resource.remediation_job_uuid, remediated_file_url)
        expect(lib_answers).to have_received(:admin_create_ticket).with(published_work_version.work.id, 'work_remediation')
      end
    end

    context 'when the service returns an unpublished new work version' do
      before do
        allow(BuildAutoRemediatedWorkVersion).to receive(:call).and_return(unpublished_work_version)
      end
      it 'does not call the LibanswersApiService' do
        described_class.perform_now(file_resource.remediation_job_uuid, remediated_file_url)
        expect(lib_answers).not_to have_received(:admin_create_ticket)
      end
    end

    context 'when the service does not return anew work version' do
      before do
        allow(BuildAutoRemediatedWorkVersion).to receive(:call).and_return(nil)
      end
      it 'does not call the LibanswersApiService' do
        described_class.perform_now(file_resource.remediation_job_uuid, remediated_file_url)
        expect(lib_answers).not_to have_received(:admin_create_ticket)
      end
    end
  end
end
