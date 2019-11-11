# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard' do
  let!(:work) { create(:work, depositor: user, versions_count: 4, has_draft: true) }
  let!(:user) { create(:user) }

  let(:work_version) { work.latest_version }

  it "lists the user's current work in published and draft states", with_user: :user do
    visit(dashboard_works_path)
    within('#user-util-collapse') do
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
          expect(page).to have_content("Published #{work_version.created_at.strftime('%B %d, %Y')} by #{user.email}")
          within('.badge') { expect(page).to have_content('published') }
        else
          expect(page).to have_content("Updated #{work_version.created_at.strftime('%B %d, %Y')} by #{user.email}")
          within('.badge') { expect(page).to have_content('draft') }
          expect(page).to have_link('edit')
          expect(page).to have_link('delete')
        end
      end
    end
  end
end
