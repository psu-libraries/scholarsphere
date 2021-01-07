# frozen_string_literal: true

require 'rails_helper'
require 'support/vcr'

RSpec.describe 'Creating and editing collections', :inline_jobs, with_user: :user do
  let(:user) { create(:user) }
  let(:actor) { user.actor }
  let(:metadata) { attributes_for(:collection, :with_complete_metadata) }
  let(:new_collection) { Collection.last }

  before do
    allow(SolrIndexingJob).to receive(:perform_now).and_call_original
  end

  context 'when creating a collection with only the required metadata' do
    it 'creates a new collection with minimal metadata' do
      initial_collection_count = Collection.count

      visit dashboard_form_collections_path

      FeatureHelpers::DashboardForm.fill_in_minimal_collection_details(metadata)
      FeatureHelpers::DashboardForm.save_and_exit

      expect(Collection.count).to eq(initial_collection_count + 1)

      expect(page).to have_content(metadata[:title])
      expect(new_collection.title).to eq metadata[:title]
      expect(new_collection.description).to eq metadata[:description]
      expect(new_collection.creators).to be_empty
      expect(new_collection.works).to be_empty

      expect(page).to have_current_path(resource_path(new_collection.uuid))
      expect(SolrIndexingJob).to have_received(:perform_now).once
    end
  end

  context 'when creating a collection with complete metadata and member works', :vcr do
    let!(:published_work) { create(:work, has_draft: false, depositor: actor) }
    let!(:proxy_work) { create(:work, has_draft: false, proxy_depositor: actor) }
    let!(:edit_work) { create(:work, has_draft: false, edit_users: [user]) }

    let(:another_user) { create(:user) }

    before do
      create(:work, depositor: actor)
      create(:work, has_draft: false, depositor: another_user.actor)
    end

    it 'steps through each tab of the form until the collection is complete', js: true do
      initial_collection_count = Collection.count

      visit dashboard_form_collections_path

      #
      # Details tab
      #

      FeatureHelpers::DashboardForm.fill_in_collection_details(metadata)
      FeatureHelpers::DashboardForm.save_and_continue
      expect(SolrIndexingJob).not_to have_received(:perform_now)

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
      within('#creator_aliases') do
        expect(page).to have_content('CREATOR 1')
        expect(find_field('Display Name').value).to eq("#{actor.given_name} #{actor.surname}")
        expect(page).to have_content('Given Name')
        expect(page).to have_content('Surname')
        expect(page).to have_content('Email')
        expect(page).to have_content('Access Account')
        expect(page).to have_content(actor.email)
        expect(page).to have_content(actor.given_name)
        expect(page).to have_content(actor.surname)
        expect(page).to have_content(actor.psu_id)
      end

      fill_in 'collection_contributor', with: metadata[:contributor]

      FeatureHelpers::DashboardForm.search_creators('wead')

      within('.algolia-autocomplete') do
        expect(page).to have_content('Adam Wead')
        expect(page).to have_content('Amy Weader')
        expect(page).to have_content('Nathan Andrew Weader')
      end

      find_all('.aa-suggestion').first.click

      within('#creator_aliases') do
        expect(page).to have_content('CREATOR 1')
        expect(page).to have_content('CREATOR 2')
        expect(page).to have_field('Display Name', count: 2)
      end

      FeatureHelpers::DashboardForm.save_and_continue
      expect(SolrIndexingJob).not_to have_received(:perform_now)

      expect(new_collection.creators.map(&:surname)).to contain_exactly('Wead', actor.surname)
      expect(new_collection.works).to be_empty

      #
      # Works tab
      #

      expect(page).to have_current_path(dashboard_form_members_path(new_collection))

      within('#search-works') do
        expect(page.find_all('option').map(&:value)).to contain_exactly(
          '',
          published_work.id.to_s,
          proxy_work.id.to_s,
          edit_work.id.to_s
        )
      end

      FeatureHelpers::DashboardForm.select_work(published_work.latest_published_version.title)
      FeatureHelpers::DashboardForm.finish
      expect(SolrIndexingJob).to have_received(:perform_now).once

      expect(new_collection.works).to contain_exactly(published_work)
    end
  end

  context 'when editing an existing collection' do
    let(:collection) { create(:collection, depositor: actor) }

    it 'updates the metadata of the collection' do
      visit dashboard_form_collection_details_path(collection)

      FeatureHelpers::DashboardForm.fill_in_collection_details(metadata)
      FeatureHelpers::DashboardForm.save_and_exit
      expect(SolrIndexingJob).to have_received(:perform_now).once

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

      FeatureHelpers::DashboardForm.finish
      expect(SolrIndexingJob).to have_received(:perform_now).once

      expect(page).to have_content('Collection was updated successfully')
      expect(collection.works).to be_empty
    end
  end
end
