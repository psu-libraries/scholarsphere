# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Blacklight catalog page', :inline_jobs do
  let(:user) { create(:user) }

  # Creates an array of all the published work versions.
  let(:published_work_versions) do
    Work
      .all
      .includes(versions: :creators)
      .map(&:latest_published_version)
      .reject(&:blank?)
  end

  let(:collections) do
    Collection
      .all
      .includes(:creators)
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

  let(:title_cards) do
    page.find_all('.card-title')
  end

  let(:ordered_titles) do
    Blacklight
      .default_index
      .connection
      .get(
        'select',
        params: {
          q: '*:*',
          fq: ['{!terms f=model_ssi}Work,Collection'],
          sort: 'deposited_at_dtsi desc',
          fl: ['title_tesim']
        }
      )['response']['docs'].map do |doc|
      doc['title_tesim']
    end.flatten
  end

  before do
    Array.new(10).map do
      FactoryBot.create(:work,
                        depositor: user.actor,
                        versions_count: rand(1..5),
                        has_draft: true,
                        deposited_at: Faker::Date.between(from: 1.year.ago, to: Time.zone.now))
    end

    FactoryBot.create_list(:collection,
                           2,
                           :with_creators,
                           :with_complete_metadata,
                           deposited_at: Faker::Date.between(from: 1.year.ago, to: Time.zone.now))
  end

  it 'displays the search form and facets' do
    visit search_catalog_path
    expect(page.title).to eq('ScholarSphere')
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
          within('.badge--text') do
            expect(page).to have_content(resource.aasm_state)
          end
        end

        within('.meta-table') do
          expect(page).to have_content(resource.deposited_at.to_formatted_s(:long))
        end
      end
    end

    # Ensure titles are ordered according to deposit date
    ordered_titles.each_with_index do |title, index|
      expect(title_cards[index].text).to eq(title)
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

  context 'when the search returns no results' do
    it 'displays no search results', with_user: :user do
      visit(search_catalog_path(q: 'asdfasdfasdfasdfasdfasdfasdf'))

      expect(page).to have_selector('h4', text: I18n.t('catalog.zero_results.info.heading'))
      expect(page).to have_content(I18n.t('catalog.zero_results.info.content'))
    end
  end

  context 'when the application is read-only', :read_only do
    it 'displays a message' do
      visit(search_catalog_path)

      within('.alert-warning') do
        expect(page).to have_content(I18n.t('read_only'))
      end
      expect(page).to have_link('Login', class: 'disabled')
    end
  end

  def document_id(resource)
    if resource.is_a? WorkVersion
      "document-#{resource.work.uuid}"
    else
      "document-#{resource.uuid}"
    end
  end
end
