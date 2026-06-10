# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::AuthRedirectController, type: :request do
  describe 'GET /users/auth/azure_oauth/redirect' do
    let(:work_version) { create(:work_version, :draft) }

    it 'stores return_to in session when provided' do
      return_to = '/dashboard/form/work_versions/123/files'

      get user_azure_oauth_redirect_path(return_to: return_to)

      expect(response).to have_http_status(:ok)
      expect(session['user_return_to']).to eq(return_to)
      expect(session[:suppress_omniauth_success_notice]).to eq(true)
    end

    it 'sets handoff session values when entered from files edit redirect' do
      path = dashboard_form_files_path(work_version)

      get path
      follow_redirect!

      expect(request.path).to eq(user_azure_oauth_redirect_path)
      expect(session['user_return_to']).to eq(path)
      expect(session[:suppress_omniauth_success_notice]).to eq(true)
    end

    it 'does not set suppression flag when return_to is missing' do
      get user_azure_oauth_redirect_path

      expect(response).to have_http_status(:ok)
      expect(session[:suppress_omniauth_success_notice]).to be_nil
    end
  end
end
