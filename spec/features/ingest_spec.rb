# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Migration', :inline_jobs, type: :feature do
  let(:user) { create(:user) }
  let(:work) { build(:work_version, :with_complete_metadata) }

  let(:metadata) do
    HashWithIndifferentAccess.new(
      work.metadata.merge(
        work_type: 'dataset',
        visibility: Permissions::Visibility::OPEN,
        creators_attributes: [
          {
            display_name: user.name,
            actor_attributes: {
              email: user.email,
              given_name: user.actor.given_name,
              surname: user.actor.surname,
              psu_id: user.actor.psu_id
            }
          }
        ]
      )
    )
  end

  let(:depositor) do
    HashWithIndifferentAccess.new(
      email: user.email,
      given_name: user.actor.given_name,
      surname: user.actor.surname,
      psu_id: user.actor.psu_id
    )
  end

  let(:content) do
    [
      HashWithIndifferentAccess.new(file: fixture_file_upload(File.join(fixture_path, 'image.png'))),
      HashWithIndifferentAccess.new(file: fixture_file_upload(File.join(fixture_path, 'ipsum.pdf')))
    ]
  end

  before do
    PublishNewWork.call(metadata: metadata, depositor: depositor, content: content)
  end

  context 'when logged in as a public user' do
    it 'shows the migrated work in a search result' do
      visit search_catalog_path
      expect(page).to have_content(work.title)
    end
  end

  context 'when logged in as the depositor' do
    it "lists the work in the user's available works", with_user: :user do
      visit(dashboard_root_path)
      expect(page).to have_content(work.title)
    end
  end
end
