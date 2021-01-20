# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Profile', type: :feature, with_user: :user do
  let(:attributes) { attributes_for(:actor) }
  let(:updated_display_name) { "Dr. #{attributes[:default_alias]}" }

  context 'with a standard user' do
    let(:user) { create(:user) }

    it 'displays and updates my profile information' do
      visit edit_dashboard_profile_path
      expect(page).to have_content('Edit Profile')
      fill_in 'Display Name', with: updated_display_name
      fill_in 'Given Name', with: attributes[:given_name]
      fill_in 'Family Name', with: attributes[:surname]
      fill_in 'Email', with: attributes[:email]
      fill_in 'ORCiD', with: attributes[:orcid]
      expect(page).not_to have_content('Administrative privileges enabled')
      click_button 'Save'
      user.actor.reload
      expect(user.actor.given_name).to eq(attributes[:given_name])
      expect(user.actor.surname).to eq(attributes[:surname])
      expect(user.actor.orcid).to eq(attributes[:orcid])
      expect(user.actor.psu_id).to eq(user.access_id)
      expect(page).to have_content(I18n.t('navbar.heading.dashboard'))
      expect(page).to have_content(I18n.t('dashboard.profiles.update.success'))
    end
  end

  context 'when the user does not have an orcid' do
    let(:actor) { create(:actor, :without_an_orcid) }
    let(:user) { create(:user, actor: actor) }

    it 'does not require them to enter one' do
      visit edit_dashboard_profile_path
      expect(page).to have_content('Edit Profile')
      expect(page).to have_field('ORCiD', text: '')
      click_button 'Save'
      expect(page).to have_content(I18n.t('navbar.heading.dashboard'))
      expect(page).to have_content(I18n.t('dashboard.profiles.update.success'))
    end
  end

  context 'with an admin user' do
    let(:user) { create(:user, :admin) }

    it 'offers the option to enable admin privileges' do
      visit edit_dashboard_profile_path
      within('#topbar') do
        expect(page).to have_content(I18n.t('navbar.admin_name'))
        expect(page).to have_link('Sidekiq')
        expect(page).to have_link('Health Checks')
      end
      expect(page).to have_content('Edit Profile')
      expect(page).to have_field('Administrative privileges enabled', checked: true)
      uncheck('Administrative privileges enabled')
      click_button 'Save'
      user.reload
      expect(user.admin_enabled).to be(false)
      expect(page).to have_content(I18n.t('navbar.heading.dashboard'))
      expect(page).to have_content(I18n.t('dashboard.profiles.update.success'))
      within('#topbar') do
        expect(page).to have_content(user.access_id)
        expect(page).not_to have_link('Sidekiq')
        expect(page).not_to have_link('Health Checks')
      end
    end
  end
end
