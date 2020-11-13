# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Azure OAuth', type: :request do
  describe 'GET /users/auth/azure_oauth' do
    it 'does not redirect' do
      get user_azure_oauth_omniauth_authorize_path
      expect(response).not_to have_http_status(:redirect)
    end
  end

  describe 'POST /users/auth/azure_oauth without CSRF token' do
    before do
      @allow_forgery_protection = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true
    end

    after { ActionController::Base.allow_forgery_protection = @allow_forgery_protection }

    it 'raises an error' do
      expect {
        post user_azure_oauth_omniauth_authorize_path
      }.to raise_error(ActionController::InvalidAuthenticityToken)
    end
  end
end
