# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Auth handoff flow', type: :request do
  # This request spec is our full-flow integration test for external entry auth:
  # files edit entry -> auth handoff route -> omniauth callback -> return to files edit.
  let(:oauth_response) { build(:psu_oauth_response) }
  let(:user) { build_stubbed(:user) }
  let(:work_version) { create(:work_version, :draft) }

  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:azure_oauth] = oauth_response

    allow(User).to receive(:from_omniauth)
      .with(oauth_response)
      .and_return(user)

    allow(user).to receive(:psu_affiliated?)
      .and_return(true)
  end

  after do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:azure_oauth] = nil
  end

  it 'returns user to files edit and suppresses success flash after handoff login' do
    files_path = dashboard_form_files_path(work_version)

    get files_path
    expect(response).to redirect_to(user_azure_oauth_redirect_path(return_to: files_path))

    follow_redirect!
    expect(response).to have_http_status(:ok)
    expect(session['user_return_to']).to eq(files_path)
    expect(session[:suppress_omniauth_success_notice]).to eq(true)

    get '/users/auth/azure_oauth/callback'

    expect(response).to redirect_to(files_path)
    expect(flash[:notice]).to be_nil
    expect(session[:suppress_omniauth_success_notice]).to be_nil
  end
end
