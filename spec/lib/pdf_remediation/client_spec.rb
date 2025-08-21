# frozen_string_literal: true

require 'spec_helper'
require 'pdf_remediation/client'

RSpec.describe PDFRemediation::Client do
  let(:client) { described_class.new('test url') }
  let(:connection) { instance_double Faraday::Connection }
  let(:request) { instance_spy Faraday::Request }
  let(:response) { instance_double Faraday::Response }
  let!(:endpoint) { ENV['PDF_REMEDIATION_ENDPOINT'] }
  let!(:api_key) { ENV['PDF_REMEDIATION_API_KEY'] }

  before do
    allow(Faraday).to receive(:new).with(
      url: endpoint,
      headers: { 'X-API-KEY' => api_key }
    ).and_return connection

    allow(connection).to receive(:post).and_yield(request).and_return(response)
    allow(response).to receive_messages(status: 200, body: %{{"uuid": "uuid-123"}})
  end

  describe '#request_remediation' do
    context 'when PDF_REMEDIATION_ENDPOINT has not been configured' do
      before { ENV['PDF_REMEDIATION_ENDPOINT'] = nil }
      after { ENV['PDF_REMEDIATION_ENDPOINT'] = endpoint }

      it 'raises an error' do
        expect { client.request_remediation }.to raise_error PDFRemediation::Client::MissingConfiguration
      end
    end

    context 'when PDF_REMEDIATION_API_KEY has not been configured' do
      before { ENV['PDF_REMEDIATION_API_KEY'] = nil }
      after { ENV['PDF_REMEDIATION_API_KEY'] = api_key }

      it 'raises an error' do
        expect { client.request_remediation }.to raise_error PDFRemediation::Client::MissingConfiguration
      end
    end

    context 'when Faraday::Error is raised' do
      before { allow(connection).to receive(:post).and_raise Faraday::Error }

      it 'raises an error' do
        expect { client.request_remediation }.to raise_error PDFRemediation::Client::ConnectionError
      end
    end

    it 'posts the given URL to the PDF remediation endpoint' do
      client.request_remediation
      expect(request).to have_received(:body=).with({ source_url: 'test url' })
    end

    context 'when the request to the endpoint returns a 200 response' do
      it 'returns the UUID of the remediation job that was created' do
        expect(client.request_remediation).to eq 'uuid-123'
      end
    end

    context 'when the request to the endpoint returns a 401 response' do
      before { allow(response).to receive(:status).and_return 401 }

      it 'raises an error' do
        expect { client.request_remediation }.to raise_error PDFRemediation::Client::InvalidAPIKey
      end
    end

    context 'when the request to the endpoint returns a 422 response' do
      before { allow(response).to receive(:status).and_return 422 }

      it 'raises an error' do
        expect { client.request_remediation }.to raise_error PDFRemediation::Client::InvalidFileURL
      end
    end
  end
end
