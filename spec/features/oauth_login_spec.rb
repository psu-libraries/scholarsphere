# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Logging in using OAuth' do
  let(:user) { create(:user) }
  let(:oauth_response) { build(:psu_oauth_response, access_id: user.access_id) }

  context 'when the user has signed in' do
    before do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:azure_oauth] = oauth_response
      login_as(user)
    end

    it 'successfully displays the page' do
      visit(dashboard_root_path)
      expect(page).to have_content(I18n.t('navbar.heading.dashboard'))
      expect(page).to have_content(user.reload.name)
    end
  end

  context 'when the user has NOT signed in' do
    it 'redirects the user to the homepage with an alert' do
      visit(dashboard_root_path)
      expect(page).to have_content('Welcome to ScholarSphere')
      within('.alert-warning') do
        expect(page).to have_content('You need to sign in or sign up before continuing')
      end
    end
  end
end
