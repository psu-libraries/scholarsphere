# frozen_string_literal: true

require 'rails_helper'
require 'support/vcr'

RSpec.describe 'Creating and editing collections', :inline_jobs, with_user: :user do
  let(:user) { create(:user) }
  let(:actor) { user.actor }
  let(:metadata) { attributes_for(:collection, :with_complete_metadata) }
  let(:new_collection) { Collection.last }

  before do
    mock_solr_indexing_job
  end

  # When stepping through each page of the form, we want to test whether the
  # collection was indexed, and how, based on the buttons that were pressed.
  # Because there can be multiple of these steps within each test, and because
  # RSpec mocks _cumulatively_ record the number of times they've been called,
  # we need a way to say "from this exact point, you should have been called
  # once." We accomplish this by tearing down the mock and setting it back up.
  def mock_solr_indexing_job
    RSpec::Mocks.space.proxy_for(SolrIndexingJob)&.reset

    allow(SolrIndexingJob).to receive(:perform_later).and_call_original
  end

  context 'when creating a collection with only the required metadata' do
    it 'creates a new collection with minimal metadata' do
      initial_collection_count = Collection.count

      visit dashboard_form_collections_path

      mock_solr_indexing_job
      FeatureHelpers::DashboardForm.fill_in_minimal_collection_details(metadata)
      FeatureHelpers::DashboardForm.save_and_exit

      expect(Collection.count).to eq(initial_collection_count + 1)

      expect(page).to have_content(metadata[:title])
      expect(new_collection.title).to eq metadata[:title]
      expect(new_collection.description).to eq metadata[:description]
      expect(new_collection.creators).to be_empty
      expect(new_collection.works).to be_empty

      expect(page).to have_current_path(resource_path(new_collection.uuid))
      expect(SolrIndexingJob).to have_received(:perform_later).once
    end
  end

  context 'when creating a collection with complete metadata and member works', :vcr do
    let!(:published_work) { create(:work, has_draft: false, depositor: actor) }
    let!(:published_work_with_draft) { create(:work, has_draft: true, versions_count: 3, depositor: actor) }
    let!(:proxy_work) { create(:work, has_draft: false, proxy_depositor: actor) }
    let!(:edit_work) { create(:work, has_draft: false, edit_users: [user]) }
    let!(:draft_work) { create(:work, depositor: actor) }
    let!(:other_work) { create(:work, has_draft: false, depositor: another_user.actor) }

    let(:another_user) { create(:user) }

    it 'steps through each tab of the form until the collection is complete', :js do
      initial_collection_count = Collection.count

      visit dashboard_form_collections_path

      #
      # Details tab
      #

      mock_solr_indexing_job
      FeatureHelpers::DashboardForm.fill_in_collection_details(metadata)
      FeatureHelpers::DashboardForm.save_and_continue
      expect(SolrIndexingJob).to have_received(:perform_later).once

      expect(Collection.count).to eq(initial_collection_count + 1)

      expect(new_collection.title).to eq metadata[:title]
      expect(new_collection.description).to eq metadata[:description]
      expect(new_collection.published_date).to eq metadata[:published_date]
      expect(new_collection.keyword).to eq [metadata[:keyword]]
      expect(new_collection.subtitle).to eq metadata[:subtitle]
      expect(new_collection.publisher).to eq [metadata[:publisher]]
      expect(new_collection.identifier).to eq [metadata[:identifier]]
      expect(new_collection.related_url).to eq [metadata[:related_url]]
      expect(new_collection.subject).to eq [metadata[:subject]]
      expect(new_collection.language).to eq [metadata[:language]]
      expect(new_collection.based_near).to eq [metadata[:based_near]]
      expect(new_collection.source).to eq [metadata[:source]]
      expect(new_collection.creators).to be_empty
      expect(new_collection.works).to be_empty

      #
      # Contributors tab
      #

      expect(page).to have_current_path(dashboard_form_contributors_path('collection', new_collection))

      # By default, it includes the current user as a creator
      within('#creators') do
        expect(page).to have_content('CREATOR 1')
        expect(find_field('Display Name').value).to eq("#{actor.given_name} #{actor.surname}")
        expect(page).to have_field('Given Name')
        expect(page).to have_field('Family Name')
        expect(page).to have_field('Email')
        expect(page).to have_content("Access Account: #{actor.psu_id}".upcase)
      end

      fill_in 'collection_contributor', with: metadata[:contributor]

      FeatureHelpers::DashboardForm.search_creators('wead')

      within('.algolia-autocomplete') do
        expect(page).to have_content('Adam Wead')
        expect(page).to have_content('Amy Weader')
        expect(page).to have_content('Nathan Andrew Weader')
      end

      find_all('.aa-suggestion').first.click

      within('#creators') do
        expect(page).to have_content('CREATOR 1')
        expect(page).to have_content('CREATOR 2')
        expect(page).to have_field('Display Name', count: 2)
      end

      mock_solr_indexing_job
      FeatureHelpers::DashboardForm.save_and_continue

      expect(SolrIndexingJob).to have_received(:perform_later).once

      expect(new_collection.creators.map(&:surname)).to contain_exactly('Wead', actor.surname)
      expect(new_collection.works).to be_empty

      #
      # Works tab
      #

      expect(page).to have_current_path(dashboard_form_members_path(new_collection))

      find_all('.select2').first.click

      expect(page).to have_css('li[data-select2-id]', count: 5)

      expect(page).to have_css('li[data-select2-id]', text: published_work.representative_version.title)
      expect(page).to have_css('li[data-select2-id]', text: published_work_with_draft.representative_version.title)
      expect(page).to have_css('li[data-select2-id]', text: proxy_work.representative_version.title)
      expect(page).to have_css('li[data-select2-id]', text: edit_work.representative_version.title)
      expect(page).to have_css('li[data-select2-id]', text: draft_work.representative_version.title)
      expect(page).to have_no_css('li[data-select2-id]', text: other_work.representative_version.title)

      mock_solr_indexing_job
      FeatureHelpers::DashboardForm.select_work(published_work.representative_version.title)

      # Test that the work that was selected no longer appears in the dropdown
      find_all('.select2').first.click
      expect(page).to have_css('li[data-select2-id]', count: 4)
      expect(page).to have_no_css('li[data-select2-id]', text: published_work.representative_version.title)

      FeatureHelpers::DashboardForm.finish
      expect(SolrIndexingJob).to have_received(:perform_later).once

      expect(new_collection.works).to contain_exactly(published_work)
    end
  end

  context 'when editing an existing collection' do
    let(:collection) { create(:collection, depositor: actor) }

    it 'updates the metadata of the collection' do
      visit dashboard_form_collection_details_path(collection)

      mock_solr_indexing_job
      FeatureHelpers::DashboardForm.fill_in_collection_details(metadata)
      FeatureHelpers::DashboardForm.save_and_exit
      expect(SolrIndexingJob).to have_received(:perform_later).once

      collection.reload
      expect(collection.title).to eq metadata[:title]
      expect(collection.description).to eq metadata[:description]
      expect(collection.published_date).to eq metadata[:published_date]
      expect(collection.keyword).to eq [metadata[:keyword]]
      expect(collection.subtitle).to eq metadata[:subtitle]
      expect(collection.publisher).to eq [metadata[:publisher]]
      expect(collection.identifier).to eq [metadata[:identifier]]
      expect(collection.related_url).to eq [metadata[:related_url]]
      expect(collection.subject).to eq [metadata[:subject]]
      expect(collection.language).to eq [metadata[:language]]
      expect(collection.based_near).to eq [metadata[:based_near]]
      expect(collection.source).to eq [metadata[:source]]
      expect(collection.creators).to be_empty
      expect(collection.works).to be_empty
    end
  end

  context 'when a collection has no works' do
    let(:collection) { create(:collection, depositor: actor) }

    it 'updates successfully' do
      visit(dashboard_form_members_path(collection))

      expect(collection.works).to be_empty

      mock_solr_indexing_job
      FeatureHelpers::DashboardForm.finish
      expect(SolrIndexingJob).to have_received(:perform_later).once

      expect(page).to have_content('Collection was successfully updated')
      expect(collection.works).to be_empty
    end
  end
end
