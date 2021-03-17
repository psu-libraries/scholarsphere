# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Publishing works from the API', :inline_jobs, type: :feature do
  let(:user) { create(:user, access_id: VCRHelpers.depositor) }
  let(:work) { attributes_for(:work_version, :with_complete_metadata) }
  let(:creator) { attributes_for(:authorship) }
  let(:mock_client) { instance_spy(PennState::SearchService::Client) }

  let(:metadata) do
    HashWithIndifferentAccess.new(
      title: work[:title],
      description: work[:description],
      work_type: 'dataset',
      published_date: work[:published_date],
      rights: work[:rights],
      visibility: Permissions::Visibility::OPEN,
      creators: [
        {
          display_name: creator[:display_name],
          given_name: creator[:given_name],
          surname: creator[:surname]
        }
      ]
    )
  end

  let(:content) do
    [
      HashWithIndifferentAccess.new(file: fixture_file_upload(File.join(fixture_path, 'image.png'))),
      HashWithIndifferentAccess.new(file: fixture_file_upload(File.join(fixture_path, 'ipsum.pdf')))
    ]
  end

  before do
    Api::V1::WorkPublisher.call(metadata: metadata, depositor_access_id: VCRHelpers.depositor, content: content)
  end

  context 'when logged in as a public user', vcr: VCRHelpers.depositor_cassette do
    it 'shows the work in a search result' do
      visit search_catalog_path
      click_link(work[:title])
      expect(page).to have_content(work[:description])
      expect(page).to have_content(creator[:display_name])
    end
  end

  context 'when logged in as the depositor', vcr: VCRHelpers.depositor_cassette do
    it "lists the work in the user's dashboard", with_user: :user do
      visit(dashboard_root_path)
      expect(page).to have_content(work[:title])
    end
  end
end
