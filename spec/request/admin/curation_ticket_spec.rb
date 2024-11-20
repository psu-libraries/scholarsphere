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
      before do
        allow(LibanswersApiService).to receive_message_chain(:new, :admin_create_curation_ticket).and_return('Redirect Path')
      end

      specify do
        post admin_create_curation_ticket_url(work)
        expect(response).to redirect_to('Redirect Path')
      end
    end
  end
end
