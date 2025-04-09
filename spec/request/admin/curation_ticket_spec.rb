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
      let(:libanswer_response) { instance_double LibanswersApiService }

      before do
        allow(LibanswersApiService).to receive(:new).and_return libanswer_response
      end

      context 'when the ticket type is curation' do
        before do
          allow(libanswer_response).to receive(:admin_create_curation_ticket).with(work.id.to_s).and_return('Redirect Path')
          post admin_create_curation_ticket_url(work), params: { ticket_type: 'curation' }
        end

        it 'redirects to the given path' do
          expect(response).to redirect_to('Redirect Path')
        end

        it 'calls the LibanswerApiService #create_curation_ticket' do
          expect(libanswer_response).to have_received(:admin_create_curation_ticket).with(work.id.to_s)
        end
      end

      context 'when the ticket type is other than curation' do
        before do
          allow(libanswer_response).to receive(:admin_create_accessibility_ticket).with(work.id.to_s,
                                                                                        'http://localhost:3000').and_return('Another Redirect Path')
          post admin_create_curation_ticket_url(work), params: { ticket_type: 'other' }
        end

        it 'redirects to the returned path' do
          expect(response).to redirect_to('Another Redirect Path')
        end

        it 'calls the LibanswerApiService #create_accessibility_ticket' do
          expect(libanswer_response).to have_received(:admin_create_accessibility_ticket).with(work.id.to_s, request.base_url)
        end
      end
    end
  end
end
