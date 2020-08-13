# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Blacklight catalog page', :inline_jobs do
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
    click_link('100 per page')

    expect(page).to have_content("1 - #{indexed_resources.count} of #{indexed_resources.count}")

    # Check facets
    expect(page).to have_selector('h3', text: 'Keywords')
    expect(page).to have_selector('h3', text: 'Subject')
    expect(page).to have_selector('h3', text: 'Creators')
    expect(page).to have_selector('h3', text: 'Work Type')

    # Display all indexed resources and check fields
    indexed_resources.each do |resource|
      within("##{document_id(resource)}") do
        expect(page).to have_link(resource.title)

        # The following fields are only valid for WorkVersions, not Collections
        if resource.is_a? WorkVersion
          expect(page).to have_content(Work::Types.display(resource.work_type))
          within('.badge--text') do
            expect(page).to have_content(resource.aasm_state)
          end
          within('.meta') do
            expect(page).to have_content("Published Date #{resource.published_date}")
          end
        end
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
    expect(page).to have_css('th.work-version-subtitle')
    expect(page).to have_css('td.work-version-subtitle', text: work_version.subtitle)
  end

  def document_id(resource)
    if resource.is_a? WorkVersion
      "document-#{resource.work.uuid}"
    else
      "document-#{resource.uuid}"
    end
  end
end
