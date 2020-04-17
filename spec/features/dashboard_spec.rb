# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard' do
  let!(:work) { create(:work, depositor: user.actor, versions_count: 4, has_draft: true) }
  let!(:user) { create(:user) }

  let(:work_version) { work.latest_version }

  it "lists the user's current work in published and draft states", with_user: :user do
    visit(dashboard_works_path)
    within('#user-util-collapse') do
      # Must reload the user to get their current name (used below), because now
      # a user's name is updated from OAuth when they log in. Our OAuth mock
      # itself generates Fakerized attributes for the user, so we need to reload
      # the user from the DB to access these in the test.
      user.reload

      expect(page).to have_content("#{user.name} (#{user.access_id})")
      expect(page).to have_link('Works')
    end
    expect(page).to have_selector('h1', text: 'Your ScholarSphere Deposits')
    expect(page).to have_link('New Work')
    within('.work-list__work') do
      expect(page).to have_selector('h3', text: work_version.title)
      expect(page).to have_selector('h5', text: work.work_type.capitalize)
    end
    page.all('.work-version').each_with_index do |row, index|
      within(row) do
        expect(page).to have_link("Version #{index + 1}")
        if index < 3
          expect(page).to have_content("Published #{work_version.created_at.strftime('%B %d, %Y')} by #{user.actor.email}")
          within('.badge') { expect(page).to have_content('published') }
        else
          expect(page).to have_content("Updated #{work_version.created_at.strftime('%B %d, %Y')} by #{user.actor.email}")
          within('.badge') { expect(page).to have_content('draft') }
          expect(page).to have_link('edit')
          expect(page).to have_link('delete')
        end
      end
    end
  end
end
