# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LibanswersApiService do
  let(:active_member) { object_double(PsuIdentity::SearchService::Person.new, affiliation: ['FACULTY', 'MEMBER']) }
  let(:mock_identity_search) { instance_spy('PsuIdentity::SearchService::Client') }
  let!(:user) { create(:user, access_id: 'test', email: 'test@psu.edu') }
  let!(:work) { create(:work, depositor: user.actor) }
  let!(:collection) { create(:collection, depositor: user.actor) }
  let!(:curation_quid) { '5477' }
  let!(:accessibility_quid) { '2590' }
  let(:mock_faraday_connection) { instance_spy Faraday::Connection }
  let(:dummy_response) { OpenStruct.new(env: OpenStruct.new(status: 200, response_body: '{"ticketUrl": "/admin/ticket?qid=13226122"}')) }

  before do
    allow(PsuIdentity::SearchService::Client).to receive(:new).and_return(mock_identity_search)
    allow(mock_identity_search).to receive(:userid).and_return(active_member)

    allow(Faraday).to receive(:new).with(
      url: 'https://psu.libanswers.com'
    ).and_return mock_faraday_connection

    allow(mock_faraday_connection).to receive(:post).and_return(dummy_response)
  end

  describe '#curate_work_ticket' do
    context 'when successful response is returned from libanswers /ticket/create endpoint' do
      it 'returns the url of the ticket created' do
        expect(described_class.new.curate_work_ticket(work.id)).to eq 'https://psu.libanswers.com/admin/ticket?qid=13226122'
      end
    end

    context 'when there is a connection error' do
      before do
        allow(Faraday).to receive(:new).and_raise Faraday::ConnectionFailed, 'Error Message'
      end

      it 'raises a LibanswersApiError' do
        expect { described_class.new.curate_work_ticket(work.id) }
          .to raise_error LibanswersApiService::LibanswersApiError, 'Error Message'
      end
    end

    context 'when creating a question for the ticket' do
      it 'uses id 5477 for quid and ScholarSphere Deposit Curation for question' do
        described_class.new.curate_work_ticket(work.id)
        expect(mock_faraday_connection).to have_received(:post).with(
          '/api/1.1/ticket/create',
          "quid=#{curation_quid}&pquestion=ScholarSphere Deposit Curation: #{
          work.latest_version.title}&pname=#{work.display_name}&pemail=#{work.email}"
        )
      end
    end

    context 'when the user is not an active member' do
      let!(:inactive_member) { object_double(PsuIdentity::SearchService::Person.new, affiliation: ['MEMBER']) }

      before do
        allow(mock_identity_search).to receive(:userid).and_return(inactive_member)
      end

      it 'raises an error' do
        expect { described_class.new.curate_work_ticket(work.id) }.to raise_error(
          LibanswersApiService::LibanswersApiError, I18n.t('resources.contact_depositor_button.error_message')
        )
      end
    end
  end

  describe '#curate_collection_ticket' do
    let!(:work) { create(:work, depositor: user.actor) }

    it 'uses id 5477 for quid and ScholarSphere Collection Curation for question' do
      described_class.new.curate_collection_ticket(collection.id)
      expect(mock_faraday_connection).to have_received(:post).with(
        '/api/1.1/ticket/create',
        "quid=#{curation_quid}&pquestion=ScholarSphere Collection Curation: #{
        collection.metadata['title']}&pname=#{collection.depositor.display_name}&pemail=#{work.depositor.email}"
      )
    end

    context 'when the user is not an active member' do
      let!(:inactive_member) { object_double(PsuIdentity::SearchService::Person.new, affiliation: ['MEMBER']) }

      before do
        allow(mock_identity_search).to receive(:userid).and_return(inactive_member)
      end

      it 'raises an error' do
        expect { described_class.new.curate_collection_ticket(collection.id) }.to raise_error(
          LibanswersApiService::LibanswersApiError, I18n.t('resources.contact_depositor_button.error_message')
        )
      end
    end
  end

  describe '#accessibility_check_ticket' do
    it 'uses id 2590 for quid and ScholarSphere Deposit Accessibility Curation for question' do
      described_class.new.accessibility_check_ticket(work.id)
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
        described_class.new.accessibility_check_ticket(work_2.id)
        details = "#{file_resource.file_data['metadata']['filename']}: " +
          "#{Rails.application.routes.default_url_options[:host]}/accessibility_check_results/#{accessibility_check_result.id}"
        expect(mock_faraday_connection).to have_received(:post).with(
          '/api/1.1/ticket/create',
          "quid=#{accessibility_quid}&pquestion=ScholarSphere Deposit Accessibility Curation: #{
          work_2.latest_version.title}&pdetails=#{details}&pname=#{work_2.display_name}&pemail=#{work.email}"
        )
      end
    end
  end

  describe '#work_remediation_ticket' do
    it 'uses id 2590 for quid and ScholarSphere PDF Auto-remediation Result for question' do
      described_class.new.work_remediation_ticket(work.id, succeeded: true)
      expect(mock_faraday_connection).to have_received(:post).with(
        '/api/1.1/ticket/create',
        "quid=#{accessibility_quid}&pquestion=ScholarSphere PDF Auto-remediation Result: #{
          work.latest_version.title} at url: #{Rails.application.routes.default_url_options[:host]}/resources/#{
          work.uuid}&pname=#{work.display_name}&pemail=#{work.email}"
      )
    end

    context 'when the ticket is a Work Remediation failed ticket' do
      it 'uses id 2590 for quid and ScholarSphere PDF Auto-remediation Result for question but includes details' do
        described_class.new.work_remediation_ticket(work.id, succeeded: false)
        expect(mock_faraday_connection).to have_received(:post).with(
          '/api/1.1/ticket/create',
          "quid=#{accessibility_quid}&pquestion=ScholarSphere PDF Auto-remediation Result: #{
          work.latest_version.title} at url: #{
          Rails.application.routes.default_url_options[:host]}/resources/#{
          work.uuid}&pname=#{
          work.display_name}&pemail=#{
          work.email}&pdetails=A PDF associated with this work failed to auto-remediate and requires manual review."
        )
      end
    end
  end

  describe '#request_alternate_format' do
    let! (:request) { build(:alternate_format_request) }

    context 'when called' do
      it 'makes a call to the LibAnswers Api' do
        expect(described_class.new.request_alternate_format(request)).to eq 'https://psu.libanswers.com/admin/ticket?qid=13226122'
      end
    end

    context 'when unsuccessful response is returned from libanswers /ticket/create endpoint' do
      let(:bad_response) { OpenStruct.new(env: OpenStruct.new(status: 500, response_body: '{"error": "Error saving ticket."}')) }

      before do
        allow(mock_faraday_connection).to receive(:post).and_return bad_response
      end

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
