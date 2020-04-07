# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Logging in using OAuth' do
  let(:user) { create(:user) }
  let(:oauth_response) { build(:psu_oauth_response, access_id: user.access_id) }

  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:psu] = oauth_response
  end

  it 'uses OAuth to authenticate to the application' do
    visit(dashboard_works_path)
    expect(page).to have_content(I18n.t('devise.omniauth_callbacks.success', kind: 'Penn State'))
    expect(page).to have_content(I18n.t('dashboard.works.index.heading'))
    expect(page).to have_content(user.reload.name)
  end
end
