# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HealthChecks::Dois do
  describe '#check' do
    context 'when no draft DOIs are detected', :vcr do
      it 'returns no failure' do
        hc = described_class.new
        hc.check
        expect(hc.failure_occurred).to be_nil
      end

      it 'writes a message' do
        hc = described_class.new
        hc.check
        expect(hc.message).to eq('Found 0 draft dois')
      end
    end

    context 'when a draft DOI exists' do
      let(:mock_client) { instance_spy('DataCite::Client') }
      let(:mock_response) { { 'meta' => { 'total' => 1 } } }

      before do
        allow(DataCite::Client).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:search).and_return(mock_response)
      end

      it 'returns a failure' do
        hc = described_class.new
        hc.check
        expect(hc.failure_occurred).to be(true)
      end

      context 'when it does NOT exceed the threshold' do
        it 'returns no failure' do
          hc = described_class.new(1)
          hc.check
          expect(hc.failure_occurred).to be_nil
        end
      end
    end
  end
end
