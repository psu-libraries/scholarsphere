# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard Work History', with_user: :user do
  let(:user) { create :user }
  let(:work) { create :work, versions_count: 2, has_draft: true, depositor: user }

  before do
    # This is usuall done in the controller, but we need to do it here to get
    # our user on the changes both made in the factory and below
    PaperTrail.request.whodunnit = user.id

    work.draft_version.update!(
      title: 'MY UPDATED TITLE',
      subtitle: 'MY UPDATED SUBTITLE'
    )
  end

  it 'shows the edit history of the work' do
    visit dashboard_work_history_path(work)

    within '.work-history' do
      expect(page).to have_content 'Version 1'
      expect(page).to have_content 'Version 2'
    end

    within "#work_version_changes_#{work.latest_published_version.id}" do
      expect(page).to have_content 'Created'
    end

    within "#work_version_changes_#{work.draft_version.id}" do
      expect(page).to have_content 'Created'
      expect(page).to have_content 'Updated'
      expect(page).to have_content 'title, subtitle' # changed attributes
      expect(page).to have_content 'MY UPDATED TITLE' # diff
      expect(page).to have_content user.access_id
    end
  end
end
