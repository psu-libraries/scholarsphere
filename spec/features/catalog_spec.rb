# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Blacklight catalog page' do
  let(:user) { create(:user) }

  # Create an array of all the latest published work versions. Some works may only have a draft, so we want to exclude
  # those. Using `compact` removes them because `latest_published_version` returns nil.
  let(:published_work_versions) do
    Work.all.includes(versions: :creator_aliases).map(&:latest_published_version).compact
  end

  let(:collections) do
    Collection.all.includes(:creator_aliases)
  end

  let(:indexed_resources) { published_work_versions + collections }

  # Select a random work version for inspection.
  let(:work_version) do
    published_work_versions.sample
  end

  # Select a random collection for inspection.
  let(:collection) do
    collections.sample
  end

  before do
    Array.new(10).map do
      FactoryBot.create(:work, depositor: user.actor, versions_count: rand(1..5), has_draft: true)
    end

    FactoryBot.create_list(:collection, 2, :with_creators, :with_complete_metadata)
  end

  it 'displays the search form and facets' do
    visit search_catalog_path
    click_button('Search')
    click_link('100 per page')

    expect(page).to have_content("1 - #{indexed_resources.count} of #{indexed_resources.count}")

    # Check facets
    expect(page).to have_selector('h3', text: 'Status')
    expect(page).to have_selector('h3', text: 'Keywords')
    expect(page).to have_selector('h3', text: 'Subject')
    expect(page).to have_selector('h3', text: 'Creators')

    # Display all indexed resources and check fields
    expect(page).to have_blacklight_label('title_tesim')
    expect(page).to have_blacklight_label('creator_aliases_tesim')
    expect(page).to have_blacklight_label('aasm_state_tesim')
    expect(page).to have_blacklight_label('keyword_tesim')
    expect(page).to have_blacklight_label('resource_type_tesim')
    expect(page).to have_blacklight_label('created_at_dtsi')
    indexed_resources.each do |resource|
      expect(page).to have_blacklight_field('title_tesim').with(resource.title)
      expect(page).to have_blacklight_field('creator_aliases_tesim').with(resource.creator_aliases.map(&:alias).join(', '))
      expect(page).to have_blacklight_field('keyword_tesim').with(resource.keyword.join(', '))
      expect(page).to have_blacklight_field('created_at_dtsi').with(/^#{resource.created_at.strftime("%F")}/)

      # The following fields are only valid for WorkVersions, not Collections
      if resource.is_a? WorkVersion
        expect(page).to have_blacklight_field('aasm_state_tesim').with(resource.aasm_state)
        expect(page).to have_blacklight_field('resource_type_tesim').with(resource.resource_type.join(', '))
      end
    end

    # Ensure a random work version has a link to the resource page
    expect(page).to have_link(work_version.title, href: resource_path(work_version.work.uuid))

    # Ensure a random collection has a link to the resource page
    expect(page).to have_link(collection.title, href: resource_path(collection.uuid))

    # Show a random work_version
    # Note this is rudimentary because it's fully tested in the WorkVersionMetadataComponent
    click_link(work_version.title)
    expect(page).to have_content(work_version.title)
    expect(page).to have_css('dt.work-version-subtitle')
    expect(page).to have_css('dd.work-version-subtitle', text: work_version.subtitle)
  end
end
