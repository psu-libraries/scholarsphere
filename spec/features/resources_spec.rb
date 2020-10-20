# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Public Resources', type: :feature do
  describe 'given a work' do
    let(:work) { create :work, has_draft: false, versions_count: 2 }

    let(:v1) { work.versions.first }
    let(:v2) { work.versions.last }

    it 'displays the public resource page for the work' do
      visit resource_path(work.uuid)

      expect(page).to have_content(v2.title)

      ## Navigate to an old version
      within('.navbar .dropdown--versions') { click_on 'V1' }

      expect(page).to have_content(v1.title)
      expect(page).to have_content(I18n.t('resources.old_version.message'))
    end
  end

  describe 'given a collection without a DOI' do
    let(:collection) { create :collection, :with_complete_metadata, works: [work] }
    let(:work) { build :work, has_draft: false, versions_count: 1 }

    it 'displays the public resource page for the collection' do
      visit resource_path(collection.uuid)

      expect(page).to have_selector('h1', text: collection.title)
      expect(page).to have_content collection.description
      expect(page).to have_content work.latest_published_version.title

      within('.meta-table') do
        expect(page).to have_content(collection.title)
      end
    end
  end

  describe 'given a collection with a DOI' do
    let(:collection) { create :collection, :with_complete_metadata, :with_a_doi, works: [work] }
    let(:work) { build :work, has_draft: false, versions_count: 1 }

    it 'displays the public resource page for the collection' do
      visit resource_path(collection.uuid)

      expect(page).to have_selector('h1', text: collection.title)
      expect(page).to have_content collection.description
      expect(page).to have_content work.latest_published_version.title

      within('.meta-table') do
        expect(page).to have_content(collection.doi)
      end
    end
  end
end
