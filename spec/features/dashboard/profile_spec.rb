# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Profile', type: :feature, with_user: :user do
  let(:user) { create(:user) }
  let(:attributes) { attributes_for(:actor) }
  let(:updated_display_name) { "Dr. #{attributes[:default_alias]}" }

  it 'displays and updates my profile information' do
    visit edit_dashboard_profile_path
    expect(page).to have_content('Edit Profile')
    fill_in 'Display Name', with: updated_display_name
    fill_in 'Given Name', with: attributes[:given_name]
    fill_in 'Surname', with: attributes[:surname]
    fill_in 'Email', with: attributes[:email]
    fill_in 'ORCiD', with: attributes[:orcid]
    click_button 'Save'
    user.actor.reload
    expect(user.actor.given_name).to eq(attributes[:given_name])
    expect(user.actor.surname).to eq(attributes[:surname])
    expect(user.actor.orcid).to eq(attributes[:orcid])
    expect(user.actor.psu_id).to eq(user.access_id)
    within('#navbarDropdown') do
      expect(page).to have_content(updated_display_name)
    end
  end
end
