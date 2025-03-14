# frozen_string_literal: true

require 'rails_helper'
require 'support/vcr'

RSpec.describe LibanswersApiService, :vcr do
  describe '#admin_create_curation_ticket' do
    let!(:user) { create(:user, access_id: 'test', email: 'test@psu.edu') }
    let!(:work) { create(:work, depositor: user.actor) }

    context 'when successful response is returned from libanswers /ticket/create endpoint' do
      it 'returns the url of the ticket created' do
        expect(described_class.new.admin_create_curation_ticket('curation', work.id)).to eq 'https://psu.libanswers.com/admin/ticket?qid=13226122'
      end
    end

    context 'when unsuccessful response is returned from libanswers /ticket/create endpoint' do
      it 'raises a LibanswersApiError' do
        expect { described_class.new.admin_create_curation_ticket('curation', work.id) }
          .to raise_error LibanswersApiService::LibanswersApiError, 'Error saving ticket.'
      end
    end

    context 'when there is a connection error' do
      before do
        allow(Faraday).to receive(:new).and_raise Faraday::ConnectionFailed, 'Error Message'
      end

      it 'raises a LibanswersApiError' do
        expect { described_class.new.admin_create_curation_ticket('curation', work.id) }
          .to raise_error LibanswersApiService::LibanswersApiError, 'Error Message'
      end
    end

    context 'when a ticket type is passed in' do
      let!(:mock_faraday_connection) { instance_spy('Faraday::Connection') }
      let!(:dummy_response) { OpenStruct.new(env: OpenStruct.new(status: 200, response_body: '{"ticketUrl": "https://psu.libanswers.com/admin/ticket?qid=13226122"}')) }
      let!(:accessibility_quid) { '2590' }
      let!(:curation_quid) { '5477' }

      before do
        allow(Faraday).to receive(:new).and_return mock_faraday_connection
        allow(mock_faraday_connection).to receive(:post).and_return dummy_response
      end

      it 'uses id 5477 for curation types' do
        described_class.new.admin_create_curation_ticket('curation', work.id)
        expect(mock_faraday_connection).to have_received(:post).with(
          '/api/1.1/ticket/create',
          "quid=#{curation_quid}&pquestion=ScholarSphere Deposit Curation: #{
          work.latest_version.title}&pname=#{work.display_name}&pemail=#{work.email}"
        )
      end

      it 'uses id 2590 for accessibility types' do
        described_class.new.admin_create_curation_ticket('accessibility', work.id)
        expect(mock_faraday_connection).to have_received(:post).with(
          '/api/1.1/ticket/create',
          "quid=#{accessibility_quid}&pquestion=ScholarSphere Deposit Accessibility Curation: #{
          work.latest_version.title}&pname=#{work.display_name}&pemail=#{work.email}"
        )
      end
    end
  end

  describe '#request_alternate_format' do
    let! (:request) { build(:alternate_format_request) }

    context 'when called' do
      let!(:mock_faraday_connection) { instance_spy('Faraday::Connection') }
      let!(:dummy_response) { OpenStruct.new(env: OpenStruct.new(status: 200, response_body: '{"ticketUrl": "https://psu.libanswers.com/admin/ticket?qid=13226122"}')) }

      before do
        allow(Faraday).to receive(:new).and_return mock_faraday_connection
        allow(mock_faraday_connection).to receive(:post).and_return dummy_response
      end

      it 'makes a call to the LibAnswers Api' do
        described_class.new.request_alternate_format(request)
        expect(mock_faraday_connection).to have_received(:post)
      end
    end

    context 'when unsuccessful response is returned from libanswers /ticket/create endpoint' do
      it 'raises a LibanswersApiError' do
        expect { described_class.new.request_alternate_format(request) }
          .to raise_error LibanswersApiService::LibanswersApiError, 'Error saving ticket.'
      end
    end

    context 'when there is a connection error' do
      before do
        allow(Faraday).to receive(:new).and_raise Faraday::ConnectionFailed, 'Error Message'
      end

      it 'raises a LibanswersApiError' do
        expect { described_class.new.request_alternate_format(request) }
          .to raise_error LibanswersApiService::LibanswersApiError, 'Error Message'
      end
    end
  end
end
