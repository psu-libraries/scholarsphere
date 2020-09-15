# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Profile', type: :feature, with_user: :user do
  let(:user) { create(:user) }
  let(:updated_user) { create(:actor) }
  let(:updated_display_name) { "Dr. #{updated_user.default_alias}" }

  it 'displays and updates my profile information' do
    visit edit_dashboard_profile_path
    expect(page).to have_content('Edit Profile')
    fill_in 'Display Name', with: updated_display_name
    fill_in 'Given Name', with: updated_user.given_name
    fill_in 'Surname', with: updated_user.surname
    fill_in 'Email', with: updated_user.email
    fill_in 'ORCiD', with: updated_user.orcid
    click_button 'Save'
    user.actor.reload
    expect(user.actor.given_name).to eq(updated_user.given_name)
    expect(user.actor.surname).to eq(updated_user.surname)
    expect(user.actor.orcid).to eq(updated_user.orcid)
    expect(user.actor.psu_id).to eq(user.access_id)
    within('#navbarDropdown') do
      expect(page).to have_content(updated_display_name)
    end
  end
end
