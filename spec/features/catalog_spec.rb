# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Blacklight catalog page' do
  let(:user) { create(:user) }

  # Create an array of all the latest published work versions. Some works may only have a draft, so we want to exclude
  # those. Using `compact` removes them because `latest_published_version` returns nil.
  let(:records) do
    Work.all.map(&:latest_published_version).compact.map do |work_version|
      HashWithIndifferentAccess.new(work_version.attributes)
        .merge(creator_aliases: work_version.creator_aliases.map(&:alias))
    end
  end

  # Select a random work version for inspection.
  let(:record) do
    records.sample
  end

  # Links to the catalog record are based on the work's uuid, and not the work version. This returns the uuid
  # of the work associated with our random work version.
  let(:record_uuid) do
    WorkVersion.where(uuid: record[:uuid]).first.work.uuid
  end

  before do
    Array.new(10).map do
      FactoryBot.create(:work, depositor: user.actor, versions_count: rand(1..5), has_draft: true)
    end
  end

  it 'displays the search form and facets' do
    visit search_catalog_path
    click_button('Search')
    expect(page).to have_content("1 - #{records.count} of #{records.count}")

    # Check facets
    expect(page).to have_selector('h3', text: 'Status')
    expect(page).to have_selector('h3', text: 'Keywords')
    expect(page).to have_selector('h3', text: 'Subject')
    expect(page).to have_selector('h3', text: 'Creators')

    # Display all records and check fields
    click_link('100 per page')
    expect(page).to have_blacklight_label('title_tesim')
    expect(page).to have_blacklight_label('creator_aliases_tesim')
    expect(page).to have_blacklight_label('aasm_state_tesim')
    expect(page).to have_blacklight_label('keyword_tesim')
    expect(page).to have_blacklight_label('resource_type_tesim')
    expect(page).to have_blacklight_label('created_at_dtsi')
    records.each do |work|
      expect(page).to have_blacklight_field('title_tesim').with(work[:title])
      expect(page).to have_blacklight_field('creator_aliases_tesim').with(work[:creator_aliases].join(', '))
      expect(page).to have_blacklight_field('aasm_state_tesim').with(work[:status])
      expect(page).to have_blacklight_field('keyword_tesim').with(work[:keyword].join(', '))
      expect(page).to have_blacklight_field('resource_type_tesim').with(work[:resource_type].join(', '))
      expect(page).to have_blacklight_field('created_at_dtsi').with(/^#{work[:created_at].strftime("%F")}/)
    end

    # Ensure a random record has a link to the resource page
    expect(page).to have_link(record[:title], href: resource_path(record_uuid))

    # Show a random record
    # Note this is rudimentary because it's fully tested in the WorkVersionMetadataComponent
    click_link(record[:title])
    expect(page).to have_content(record[:title])
    expect(page).to have_css('dt.work-version-subtitle')
    expect(page).to have_css('dd.work-version-subtitle', text: record[:subtitle])
  end
end
