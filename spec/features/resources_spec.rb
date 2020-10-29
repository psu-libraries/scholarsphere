# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Public Resources', type: :feature do
  describe 'given a work' do
    let(:work) { create :work, has_draft: false, versions_count: 2 }

    let(:v1) { work.versions[0] }
    let(:v2) { work.versions[1] }

    context 'when I am not logged in (i.e. as a public user)' do
      it 'displays the public resource page for the work' do
        visit resource_path(work.uuid)

        expect(page).to have_content(v2.title)

        ## Does not have edit controls
        within('header') do
          expect(page).not_to have_content(I18n.t('resources.edit_button.text', version: 'V2'))
        end

        ## Navigate to an old version
        within('.navbar .dropdown--versions') { click_on 'V1' }

        expect(page).to have_content(v1.title)
        expect(page).to have_content(I18n.t('resources.old_version.message'))
      end
    end

    context 'when logged in as the resource owner', with_user: :user do
      let(:user) { work.depositor.user }

      before { visit resource_path(work.uuid) }

      context 'when no draft exists' do
        it 'displays edit controls on the resource page' do
          expect(page).to have_content(v2.title) # Sanity

          within('header') do
            ## Edit controls are visible
            expect(page).to have_content(I18n.t('resources.edit_button.text', version: 'V2'))
              .and have_content(I18n.t('resources.create_button.text', version: 'V2'))

            ## Edit button is disabled, create draft button is enabled
            expect(page).to have_selector('.qa-edit-version.disabled')
            expect(page).to have_selector('.qa-create-draft')
            expect(page).not_to have_selector('.qa-create-draft.disabled')
          end

          ## Navigate to an old version
          within('.navbar .dropdown--versions') { click_on 'V1' }

          within('header') do
            ## Edit and create draft buttons are now both disabled
            expect(page).to have_selector('.qa-edit-version.disabled')
            expect(page).to have_selector('.qa-create-draft.disabled')
          end
        end
      end

      context 'when a draft exists' do
        let(:work) { create :work, has_draft: true, versions_count: 3 }

        it 'displays edit controls on the resource page' do
          expect(page).to have_content(v2.title) # Sanity

          within('header') do
            ## Edit and create buttons are disabled
            expect(page).to have_selector('.qa-edit-version.disabled')
            expect(page).to have_selector('.qa-create-draft.disabled')
          end

          ## Navigate to draft version
          within('.navbar .dropdown--versions') { click_on 'V3' }

          within('header') do
            ## Edit button enabled, create button disabled
            expect(page).to have_selector('.qa-edit-version')
            expect(page).not_to have_selector('.qa-edit-version.disabled')
            expect(page).to have_selector('.qa-create-draft.disabled')
          end
        end
      end
    end

    context 'when the work is present in a collection' do
      let(:collection) { create(:collection) }
      let(:work) { create(:work, has_draft: false, collections: [collection]) }

      it 'displays information about the collection' do
        visit resource_path(work.uuid)

        expect(page).to have_link(collection.title)
      end
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
