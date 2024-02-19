# frozen_string_literal: true

require 'rails_helper'
require 'support/vcr'

RSpec.describe LibanswersApiService, :vcr do
  describe '#admin_create_curation_ticket' do
    let!(:user) { create :user, access_id: 'test', email: 'test@psu.edu' }
    let!(:work) { create :work, depositor: user.actor }

    context 'when successful response is returned from libanswers /ticket/create endpoint' do
      it 'returns the url of the ticket created' do
        expect(described_class.new(work.id).admin_create_curation_ticket).to eq 'https://psu.libanswers.com/admin/ticket?qid=13226122'
      end
    end

    context 'when unsuccessful response is returned from libanswers /ticket/create endpoint' do

      it 'raises a LibanswersApiError' do
        expect { described_class.new(work.id).admin_create_curation_ticket }
          .to raise_error LibanswersApiService::LibanswersApiError, 'Error saving ticket.'
      end
    end

    context 'when there is a connection error' do
      before do
        allow(Faraday).to receive(:new).and_raise Faraday::ConnectionFailed, 'Error Message'
      end

      it 'raises a LibanswersApiError' do
        expect { described_class.new(work.id).admin_create_curation_ticket }
          .to raise_error LibanswersApiService::LibanswersApiError, 'Error Message'
      end
    end
  end
end
