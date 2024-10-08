# frozen_string_literal: true

require 'rails_helper'
require 'support/vcr'

RSpec.describe LibanswersApiService, :vcr do
  describe '#admin_create_curation_ticket' do
    let!(:user) { create :user, access_id: 'test', email: 'test@psu.edu' }
    let!(:work) { create :work, depositor: user.actor }

    context 'when successful response is returned from libanswers /ticket/create endpoint' do
      it 'returns the url of the ticket created' do
        expect(described_class.new(work.id, 'curation').admin_create_curation_ticket).to eq 'https://psu.libanswers.com/admin/ticket?qid=13226122'
      end
    end

    context 'when unsuccessful response is returned from libanswers /ticket/create endpoint' do
      it 'raises a LibanswersApiError' do
        expect { described_class.new(work.id, 'curation').admin_create_curation_ticket }
          .to raise_error LibanswersApiService::LibanswersApiError, 'Error saving ticket.'
      end
    end

    context 'when there is a connection error' do
      before do
        allow(Faraday).to receive(:new).and_return
      end

      it 'raises a LibanswersApiError' do
        expect { described_class.new(work.id, 'curation').admin_create_curation_ticket }
          .to raise_error LibanswersApiService::LibanswersApiError, 'Error Message'
      end
    end

    context 'when a ticket type of curation is passed in' do
      let(:mock_faraday) { instance_spy('Faraday::Connection') }
      before do
        allow(Faraday).to receive(:new).and_return mock_faraday
      end
      it 'sends the correct subject to libanswers' do
        ticket_request = described_class.new(work.id, 'curation').admin_create_curation_ticket
        expect(mock_faraday).to have_received(:post).with('/ticket/create', { subject: 'Curation dfa', question: 'Please review this work for curation.' })
      end

      it 'uses the correct queue id' do
      end
    end
  end
end
