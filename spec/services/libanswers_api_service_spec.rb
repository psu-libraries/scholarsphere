# frozen_string_literal: true

require 'rails_helper'
require 'support/vcr'

RSpec.describe LibanswersApiService, :vcr do
  let(:active_member) { object_double(PsuIdentity::SearchService::Person.new, affiliation: ['FACULTY', 'MEMBER']) }
  let(:mock_identity_search) { instance_spy('PsuIdentity::SearchService::Client') }

  before do
    allow(PsuIdentity::SearchService::Client).to receive(:new).and_return(mock_identity_search)
    allow(mock_identity_search).to receive(:userid).and_return(active_member)
  end

  describe '#admin_create_ticket' do
    let!(:user) { create(:user, access_id: 'test', email: 'test@psu.edu') }
    let!(:work) { create(:work, depositor: user.actor) }
    let!(:collection) { create(:collection, depositor: user.actor)}

    context 'when successful response is returned from libanswers /ticket/create endpoint' do
      it 'returns the url of the ticket created' do
        expect(described_class.new.admin_create_ticket(work.id)).to eq 'https://psu.libanswers.com/admin/ticket?qid=16117497'
      end
    end

    context 'when unsuccessful response is returned from libanswers /ticket/create endpoint' do
      it 'raises a LibanswersApiError' do
        expect { described_class.new.admin_create_ticket(work.id) }
          .to raise_error LibanswersApiService::LibanswersApiError, 'Error saving ticket.'
      end
    end

    context 'when there is a connection error' do
      before do
        allow(Faraday).to receive(:new).and_raise Faraday::ConnectionFailed, 'Error Message'
      end

      it 'raises a LibanswersApiError' do
        expect { described_class.new.admin_create_ticket(work.id) }
          .to raise_error LibanswersApiService::LibanswersApiError, 'Error Message'
      end
    end

    context 'when called' do
      let!(:mock_faraday_connection) { instance_spy('Faraday::Connection') }
      let!(:dummy_response) { OpenStruct.new(env: OpenStruct.new(status: 200, response_body: '{"ticketUrl": "https://psu.libanswers.com/admin/ticket?qid=13226122"}')) }
      let!(:curation_quid) { '5477' }
      let!(:accessibility_quid) { '2590' }

      before do
        allow(Faraday).to receive(:new).and_return mock_faraday_connection
        allow(mock_faraday_connection).to receive(:post).and_return dummy_response
      end

      context 'when the user is not an active member' do
        let!(:inactive_member) { object_double(PsuIdentity::SearchService::Person.new, affiliation: ['MEMBER']) }

        before do
          allow(mock_identity_search).to receive(:userid).and_return(inactive_member)
        end

        it 'raises an error' do
          expect { described_class.new.admin_create_ticket(work.id) }.to raise_error(
            LibanswersApiService::LibanswersApiError, I18n.t('resources.contact_depositor_button.error_message')
          )
        end
      end

      context 'when the ticket is a Work Curation Ticket' do
        it 'uses id 5477 for quid and ScholarSphere Deposit Curation for question' do
          described_class.new.admin_create_ticket(work.id, 'work_curation')
          expect(mock_faraday_connection).to have_received(:post).with(
            '/api/1.1/ticket/create',
            "quid=#{curation_quid}&pquestion=ScholarSphere Deposit Curation: #{
            work.latest_version.title}&pname=#{work.display_name}&pemail=#{work.email}"
          )
        end
      end

      context 'when the ticket is a Collection Curation Ticket' do
        it 'uses id 5477 for quid and ScholarSphere Collection Curation for question' do
          described_class.new.admin_create_ticket(collection.id, 'collection')
          expect(mock_faraday_connection).to have_received(:post).with(
            '/api/1.1/ticket/create',
            "quid=#{curation_quid}&pquestion=ScholarSphere Collection Curation: #{
            collection.metadata['title']}&pname=#{collection.depositor.display_name}&pemail=#{work.depositor.email}"
          )
        end
      end

      context 'when the ticket is a Work Accessibility Ticket' do
        let!(:base_url) { 'www.example.com' }

        it 'uses id 2590 for quid and ScholarSphere Deposit Accessibility Curation for question' do
          described_class.new.admin_create_ticket(work.id, 'work_accessibility', base_url)
          expect(mock_faraday_connection).to have_received(:post).with(
            '/api/1.1/ticket/create',
            "quid=#{accessibility_quid}&pquestion=ScholarSphere Deposit Accessibility Curation: #{
              work.latest_version.title}&pname=#{work.display_name}&pemail=#{work.email}"
          )
        end

        context 'when accessibility report exists' do
          let!(:work_2) { create(:work, depositor: user.actor) }
          let(:file_resource) { create(:file_resource, :pdf) }
          let(:files) { work_2.latest_version.file_resources }
          let(:accessibility_check_result) do
            create(:accessibility_check_result, file_resource_id: files.last.id, detailed_report:
              { 'Detailed Report': {} })
          end

          before do
            files << file_resource
            accessibility_check_result.save!
          end

          it 'includes "pdetails" containing an accessibility report url' do
            described_class.new.admin_create_ticket(work_2.id, 'work_accessibility', base_url )
            details = "#{file_resource.file_data['metadata']['filename']}: #{base_url}/accessibility_check_results/#{accessibility_check_result.id}"
            expect(mock_faraday_connection).to have_received(:post).with(
              '/api/1.1/ticket/create',
              "quid=#{accessibility_quid}&pquestion=ScholarSphere Deposit Accessibility Curation: #{
              work_2.latest_version.title}&pdetails=#{details}&pname=#{work_2.display_name}&pemail=#{work.email}"
            )
          end
        end
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
