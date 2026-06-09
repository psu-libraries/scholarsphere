# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::AuthRedirectController, type: :request do
  describe 'GET /users/auth/azure_oauth/redirect' do
    it 'stores return_to in session when provided' do
      return_to = '/dashboard/form/work_versions/123/files'

      get user_azure_oauth_redirect_path(return_to: return_to)

      expect(response).to have_http_status(:ok)
      expect(session['user_return_to']).to eq(return_to)
      expect(session[:suppress_omniauth_success_notice]).to eq(true)
    end
  end
end
