# frozen_string_literal: true

require 'rails_helper'
require 'support/vcr'

RSpec.describe LibanswersApiService, :vcr do
  describe '#create_ticket' do
    let(:args) do
      {
        send_to_name: 'Test Tester',
        send_to_email: 'test1@psu.edu',
        subject: 'Test Subject'
      }
    end

    context 'when successful response is returned from libanswers /ticket/create endpoint' do
      it 'returns the url of the ticket created' do
        expect(described_class.new(args).admin_create_curation_ticket).to eq 'https://psu.libanswers.com/admin/ticket?qid=123456789'
      end
    end

    context 'when unsuccessful response is returned from libanswers /ticket/create endpoint' do
      before do
        args[:subject] = nil
      end

      it 'raises a LibanswersApiError' do
        expect { described_class.new(args).admin_create_curation_ticket }
          .to raise_error LibanswersApiService::LibanswersApiError, 'Question text empty or missing from request.'
      end
    end

    context 'when there is a connection error' do
      before do
        allow(Faraday).to receive(:new).and_raise Faraday::ConnectionFailed, 'Error Message'
      end

      it 'raises a LibanswersApiError' do
        expect { described_class.new(args).admin_create_curation_ticket }
          .to raise_error LibanswersApiService::LibanswersApiError, 'Error Message'
      end
    end
  end
end
