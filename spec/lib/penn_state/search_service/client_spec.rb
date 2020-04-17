# frozen_string_literal: true

require 'spec_helper'
require 'support/vcr'
require 'penn_state/search_service'

RSpec.describe PennState::SearchService::Client do
  let(:client) { described_class.new }

  describe '#search', :vcr do
    context 'with a sucessful result' do
      let(:results) { client.search(text: 'wead') }

      it 'returns a first and last name' do
        expect(results.map(&:given_name)).to include('Adam')
        expect(results.map(&:family_name)).to include('Wead')
      end
    end

    context 'when no results are found' do
      let(:result) { client.search(text: 'asdf') }

      it 'returns an empty set' do
        expect(result).to be_empty
      end
    end

    context 'with unsupported parameters' do
      let(:result) { client.search(bogus: 'bam!') }

      it 'returns an empty set' do
        expect(result).to be_empty
      end
    end

    context 'with an unparsable response' do
      let(:mock_connection) { instance_spy('Faraday::Connection') }
      let(:mock_response) { instance_spy('Faraday::Response', body: 'this is not JSON') }
      let(:result) { client.search(text: 'asdf') }

      before do
        allow(client).to receive(:connection).and_return(mock_connection)
        allow(mock_connection).to receive(:get).and_return(mock_response)
      end

      it 'returns an empty set' do
        expect(result).to be_empty
      end
    end

    context 'when an error occurs with the connection' do
      let(:client) { described_class.new(base_url: 'bad_endpoint') }
      let(:result) { client.search(text: 'asdf') }

      it 'raises an error' do
        expect {
          result
        }.to raise_error(
          PennState::SearchService::Client::Error,
          /404 page not found/
        )
      end
    end
  end

  describe '#userid', :vcr do
    context 'when the person exists at Penn State' do
      let(:results) { client.userid('agw13') }

      it 'returns a first and last name' do
        expect(results.given_name).to include('Adam')
        expect(results.family_name).to include('Wead')
      end
    end

    context 'when the person does NOT exist at Penn State' do
      let(:results) { client.userid('cam156') }

      it 'returns nil' do
        expect(results).to be_nil
      end
    end

    context 'with an unparsable response' do
      let(:mock_connection) { instance_spy('Faraday::Connection') }
      let(:mock_response) { instance_spy('Faraday::Response', body: 'this is not JSON') }
      let(:results) { client.userid('asdf') }

      before do
        allow(client).to receive(:connection).and_return(mock_connection)
        allow(mock_connection).to receive(:get).and_return(mock_response)
      end

      it 'returns nil' do
        expect(results).to be_nil
      end
    end

    context 'when an error occurs with the connection' do
      it 'raises an error' do
        expect { client.userid(nil) }.to raise_error(PennState::SearchService::Client::Error)
      end
    end
  end
end
