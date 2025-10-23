# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BuildAutoRemediatedWorkVersionJob do
  let(:file_resource) { create(:file_resource, remediation_job_uuid: existing_job_uuid) }
  let(:existing_job_uuid) { SecureRandom.uuid }
  let(:remediated_file_url) { 'https://example.com/remediated.pdf' }

  describe '#perform' do
    before do
      allow(BuildAutoRemediatedWorkVersion).to receive(:call)
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
  end
end
