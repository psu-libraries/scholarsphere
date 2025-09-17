# frozen_string_literal: true

require 'rails_helper'
require 'pdf_remediation/client'

RSpec.describe AutoRemediationJob do
  let(:resource) { create(:file_resource, :pdf, work_versions: [create(:work_version)]) }
  let(:client) { instance_double(PdfRemediation::Client, request_remediation: 'test_uuid') }

  before do
    allow(PdfRemediation::Client).to receive(:new).and_return(client)
  end

  describe '#perform' do
    context 'when the client runs successfully' do
      it 'calls the PDF remediation client with the resource' do
        described_class.perform_now(resource.id)

        expect(PdfRemediation::Client).to have_received(:new).with(resource.file_url)
        expect(client).to have_received(:request_remediation)
        expect(resource.reload.remediation_job_uuid).to eq('test_uuid')
      end
    end

    context 'when an error occurs' do
      let(:error_message) { 'Something went wrong' }

      before do
        allow(client).to receive(:request_remediation).and_raise(StandardError, error_message)
      end

      it 'creates or updates the AccessibilityCheckResult with the error message and raises the error' do
        expect {
          described_class.perform_now(resource.id)
        }.to raise_error(StandardError, error_message)

        expect(resource.reload.remediation_job_uuid).to be_nil
      end
    end
  end
end
