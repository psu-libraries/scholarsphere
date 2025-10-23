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
        before do
          allow(libanswer_service).to receive(:admin_create_ticket).with(work.id.to_s, 'work_curation').and_return('Redirect Path')
          post admin_create_curation_ticket_url(work), params: { ticket_type: 'curation' }
        end

        it 'redirects to the given path' do
          expect(response).to redirect_to('Redirect Path')
        end

        it 'calls the LibanswerApiService #admin_create_ticket with work_curation argument' do
          expect(libanswer_service).to have_received(:admin_create_ticket).with(work.id.to_s, 'work_curation')
        end
      end

      context 'when the ticket type is accessibility' do
        before do
          allow(libanswer_service).to receive(:admin_create_ticket).with(work.id.to_s, 'work_accessibility_check',
                                                                         'http://localhost:3000').and_return('Another Redirect Path')
          post admin_create_curation_ticket_url(work), params: { ticket_type: 'accessibility' }
        end

        it 'redirects to the returned path' do
          expect(response).to redirect_to('Another Redirect Path')
        end

        it 'calls the LibanswerApiService #admin_create_ticket with work_accessibility_check argument' do
          expect(libanswer_service).to have_received(:admin_create_ticket).with(work.id.to_s, 'work_accessibility_check', request.base_url)
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

      before do
        allow(LibanswersApiService).to receive(:new).and_return libanswer_service
        allow(libanswer_service).to receive(:admin_create_ticket).with(collection.id.to_s, 'collection').and_return('Yet Another Redirect Path')
        post admin_create_collection_ticket_url(collection)
      end

      it 'redirects to the given path' do
        expect(response).to redirect_to('Yet Another Redirect Path')
      end

      it 'calls the LibanswerApiService #admin_create_ticket with collection argument' do
        expect(libanswer_service).to have_received(:admin_create_ticket).with(collection.id.to_s, 'collection')
      end
    end
  end
end
