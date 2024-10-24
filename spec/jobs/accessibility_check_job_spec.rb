# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccessibilityCheckJob, type: :job do
  let(:resource) { create(:file_resource) }
  let(:service) { instance_double(AdobePdf::AccessibilityChecker, call: true) }

  before do
    allow(AdobePdf::AccessibilityChecker).to receive(:new).and_return(service)
  end

  describe '#perform' do
    context 'when the service runs successfully' do
      it 'calls the accessibility service with the resource' do
        allow(service).to receive(:call)

        described_class.perform_now(resource.id)

        expect(AdobePdf::AccessibilityChecker).to have_received(:new).with(resource)
        expect(service).to have_received(:call)
      end
    end

    context 'when an error occurs' do
      let(:error_message) { 'Something went wrong' }

      before do
        allow(service).to receive(:call).and_raise(StandardError, error_message)
      end

      it 'creates or updates the AccessibilityCheckResult with the error message and raises the error' do
        expect {
          described_class.perform_now(resource.id)
        }.to raise_error(StandardError, error_message)

        acr = AccessibilityCheckResult.find_by(file_resource: resource)
        expect(acr.report).to eq({ 'error' => error_message })
      end
    end
  end
end
