# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create Curation Ticket', type: :request do
  before { sign_in user }

  describe 'GET /admin/works/:id/create_curation_ticket' do
    let!(:work) { create(:work) }

    context 'with a non-admin user' do
      let(:user) { create(:user) }

      specify do
        post admin_create_curation_ticket_url(work)
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with an admin user' do
      let(:user) { create(:user, :admin) }
      let(:libanswer_service) { instance_double LibanswersApiService }

      before do
        allow(LibanswersApiService).to receive(:new).and_return libanswer_service
      end

      context 'when the ticket type is curation' do
        let(:redirect_url) { 'https://psu.libanswers.com/admin/ticket?qid=13224664' }

        before do
          allow(libanswer_service).to receive(:curate_work_ticket).with(work.id.to_s).and_return(redirect_url)
          post admin_create_curation_ticket_url(work), params: { ticket_type: 'curation' }
        end

        it 'redirects to the given path' do
          expect(response).to redirect_to(redirect_url)
        end

        it 'calls the LibanswerApiService #curate_work_ticket' do
          expect(libanswer_service).to have_received(:curate_work_ticket).with(work.id.to_s)
        end
      end

      context 'when the ticket type is accessibility' do
        let(:redirect_url) { 'https://psu.libanswers.com/admin/ticket?qid=14782516' }

        before do
          allow(libanswer_service).to receive(:accessibility_check_ticket).with(
            work.id.to_s
          ).and_return(redirect_url)
          post admin_create_curation_ticket_url(work), params: { ticket_type: 'accessibility' }
        end

        it 'redirects to the returned path' do
          expect(response).to redirect_to(redirect_url)
        end

        it 'calls the LibanswerApiService #admin' do
          expect(libanswer_service).to have_received(:accessibility_check_ticket).with(work.id.to_s)
        end
      end
    end
  end

  describe 'GET /admin/collection/:id/create_collection_ticket' do
    let!(:collection) { create(:collection) }

    context 'with a non-admin user' do
      let(:user) { create(:user) }

      specify do
        post admin_create_collection_ticket_url(collection)
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with an admin user' do
      let(:user) { create(:user, :admin) }
      let(:libanswer_service) { instance_double LibanswersApiService }
      let(:redirect_url) { 'https://psu.libanswers.com/admin/ticket?qid=13226122' }

      before do
        allow(LibanswersApiService).to receive(:new).and_return libanswer_service
        allow(libanswer_service).to receive(:curate_collection_ticket).with(collection.id.to_s).and_return(redirect_url)
        post admin_create_collection_ticket_url(collection)
      end

      it 'redirects to the given path' do
        expect(response).to redirect_to(redirect_url)
      end

      it 'calls the LibanswerApiService #curate_collection_ticket' do
        expect(libanswer_service).to have_received(:curate_collection_ticket).with(collection.id.to_s)
      end
    end
  end
end
