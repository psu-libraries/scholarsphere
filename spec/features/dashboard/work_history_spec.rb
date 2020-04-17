# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard Work History', with_user: :user, versioning: true do
  let(:user) { create :user }
  let(:work) { create :work, versions_count: 1, has_draft: false, depositor: user.actor }

  before do
    # This is usually done in the controller, but we need to do it here to get
    # our user on the changes both made in the factory and below
    PaperTrail.request.whodunnit = user.id

    # Create a new draft version
    draft_version = BuildNewWorkVersion.call(work.latest_published_version)
    draft_version.save!

    # Update some attributes on the draft version
    work.draft_version.update!(
      title: 'MY UPDATED TITLE',
      subtitle: 'MY UPDATED SUBTITLE'
    )

    # Rename a file on the draft version
    work.draft_version.file_version_memberships.first.tap do |file_version_membership|
      file_version_membership.update!(title: 'MY_UPDATED_FILENAME.png')
    end
  end

  it 'shows the edit history of the work' do
    visit dashboard_work_history_path(work)

    within '.work-history' do
      expect(page).to have_content 'Version 1'
      expect(page).to have_content 'Version 2'
    end

    within "#work_version_changes_#{work.latest_published_version.id}" do
      expect(page).to have_content 'Created'
      expect(page).to have_content(/Added image-\d+.png/)
    end

    within "#work_version_changes_#{work.draft_version.id}" do
      expect(page).to have_content 'Created'
      expect(page).to have_content 'Updated'
      expect(page).to have_content 'Title, Subtitle' # changed attributes
      expect(page).to have_content 'MY UPDATED TITLE' # diff
      expect(page).to have_content user.access_id

      expect(page).not_to have_content(/Added image-\d+.png/)
      expect(page).to have_content(/Renamed image-\d+.png.+MY_UPDATED_FILENAME.png/)
    end
  end
end
