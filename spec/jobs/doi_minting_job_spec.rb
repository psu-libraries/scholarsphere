# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DoiMintingJob, type: :job do
  let(:resource) { instance_spy('Work') }
  let(:mock_doi_status) { instance_spy('DoiMintingStatus') }

  describe '#perform' do
    before do
      allow(DoiService).to receive(:call)
      allow(DoiMintingStatus).to receive(:new).and_return(mock_doi_status)
    end

    it 'calls DoiService while reporting status' do
      expect(DoiMintingStatus).to receive(:new).with(resource)

      # Order of these calls matters
      expect(mock_doi_status).to receive(:minting!).ordered
      expect(DoiService).to receive(:call).with(resource).ordered
      expect(mock_doi_status).to receive(:delete!).ordered

      described_class.perform_now(resource)
    end

    describe 'error handling' do
      [
        DoiService::Error,
        DataCite::Client::Error,
        DataCite::Metadata::Base::Error
      ].each do |potential_error|
        context "When a #{potential_error} is thrown" do
          before do
            allow(DoiService).to receive(:call).and_raise(potential_error)
          end

          it 'reports the error to the status, then raises the original error' do
            expect {
              described_class.perform_now(resource)
            }.to raise_error(potential_error)

            expect(mock_doi_status).to have_received(:error!)
          end
        end
      end
    end
  end
end
