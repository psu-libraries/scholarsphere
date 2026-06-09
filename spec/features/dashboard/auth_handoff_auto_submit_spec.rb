# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Auth handoff auto submit', :js, type: :feature do
  let(:oauth_response) { build(:psu_oauth_response) }
  let(:work_version) { create(:work_version, :draft) }
  let(:user) { work_version.depositor.user }

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

  it 'auto-submits login form and returns to files edit page' do
    files_path = dashboard_form_files_path(work_version)

    visit user_azure_oauth_redirect_path(return_to: files_path)

    expect(page).to have_current_path(files_path, wait: 10)
    expect(page).to have_no_text('Successfully authenticated')
  end
end
