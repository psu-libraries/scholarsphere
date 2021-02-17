# frozen_string_literal: true

require 'spec_helper'
require 'orcid'

RSpec.describe Orcid::Public do
  describe '::get' do
    subject(:call) { described_class.get(action: 'endpoint', id: 'id') }

    let(:connection) { instance_double('Faraday::Connection') }

    before do
      allow(Faraday).to receive(:new).and_return(connection)
      allow(connection).to receive(:get).and_return(response)
    end

    context 'with a successful response' do
      let(:response) { instance_spy('Faraday::Response', body: '{ "success": "true" }') }

      it { is_expected.to eq({ 'success' => 'true' }) }
    end

    context 'with an unparseable response' do
      let(:response) { instance_spy('Faraday::Response', body: "can't parse this") }

      it { is_expected.to be_empty }
    end

    context 'when the orcid does not exist' do
      let(:response) do
        instance_spy(
          'Faraday::Response',
          body: '{"response-code":404, "user-message":"Nothing to see here..."}',
          status: 404,
          success?: false
        )
      end

      it 'raises Orcid::NotFound' do
        expect { call }.to raise_error(Orcid::NotFound, 'Nothing to see here...')
      end
    end

    context 'with an unknown error' do
      let(:response) do
        instance_spy(
          'Faraday::Response',
          body: '{"response-code":500, "user-message":"Something went wrong."}',
          status: 500,
          success?: false
        )
      end

      it 'raises Orcid::Error' do
        expect { call }.to raise_error(Orcid::Error, 'Something went wrong.')
      end
    end
  end
end
