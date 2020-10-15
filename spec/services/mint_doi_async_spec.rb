# frozen_string_literal: true

describe MintDoiAsync do
  let(:resource) { instance_spy('Work') }
  let(:mock_doi_status) { instance_spy('DoiMintingStatus') }

  describe '.call' do
    before do
      allow(DoiMintingStatus).to receive(:new).with(resource).and_return(mock_doi_status)
      allow(DoiMintingJob).to receive(:perform_later)
    end

    it 'fires off a background job after setting appropriate status' do
      described_class.call(resource)

      expect(DoiMintingStatus).to have_received(:new).with(resource)
      expect(mock_doi_status).to have_received(:waiting!)
      expect(DoiMintingJob).to have_received(:perform_later).with(resource)
    end
  end
end
