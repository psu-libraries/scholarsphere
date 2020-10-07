# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DoiMintingJob, type: :job do
  let(:resource) { instance_spy('Work') }
  let(:mock_doi_status) { instance_spy('DoiStatus') }

  describe '#perform' do
    before do
      allow(DoiService).to receive(:call)
      allow(DoiStatus).to receive(:new).and_return(mock_doi_status)
    end

    it 'calls DoiService while reporting status' do
      expect(DoiStatus).to receive(:new).with(resource)

      # Order of these calls matters
      expect(mock_doi_status).to receive(:minting!).ordered
      expect(DoiService).to receive(:call).with(resource).ordered
      expect(mock_doi_status).to receive(:delete!).ordered

      described_class.perform_now(resource)
    end

    context 'when an error occurrs' do
      before do
        allow(DoiService).to receive(:call).with(resource).and_raise(DoiService::Error)
      end

      it 'reports the error to the status, then raises' do
        expect {
          described_class.perform_now(resource)
        }.to raise_error(DoiService::Error)

        expect(mock_doi_status).to have_received(:error!)
      end
    end
  end
end
