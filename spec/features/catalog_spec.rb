# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Blacklight catalog page' do
  let(:user) { create(:user) }

  let!(:works) do
    Array.new(10).map do
      FactoryBot.create(:work, depositor: user, versions_count: rand(1..5), has_draft: true)
    end
  end

  let(:records) do
    works.map { |work| HashWithIndifferentAccess.new(work.latest_version.attributes) }
  end

  let(:record) do
    records.sample
  end

  it 'displays the search form and facets' do
    visit search_catalog_path
    click_button('Search')
    expect(page).to have_content("1 - 10 of #{WorkVersion.count}")

    # Check facets
    expect(page).to have_selector('h3', text: 'Status')
    expect(page).to have_selector('h3', text: 'Keywords')
    expect(page).to have_selector('h3', text: 'Subject')

    # Display all records and check fields
    click_link('100 per page')
    expect(page).to have_blacklight_label('title_tesim')
    expect(page).to have_blacklight_label('aasm_state_tesim')
    expect(page).to have_blacklight_label('keywords_tesim')
    expect(page).to have_blacklight_label('resource_type_tesim')
    expect(page).to have_blacklight_label('created_at_dtsi')
    records.each do |work|
      expect(page).to have_blacklight_field('title_tesim').with(work[:title])
      expect(page).to have_blacklight_field('aasm_state_tesim').with(work[:status])
      expect(page).to have_blacklight_field('keywords_tesim').with(work[:keywords].join(', '))
      expect(page).to have_blacklight_field('resource_type_tesim').with(work[:resource_type].join(', '))
      expect(page).to have_blacklight_field('created_at_dtsi').with(work[:created_at].iso8601)
    end

    # Show a random record
    within(page.all('h3', text: record[:title]).first) do
      click_link(record[:title])
    end
    expect(page).to have_blacklight_label('title_tesim')
    expect(page).to have_blacklight_label('aasm_state_tesim')
    expect(page).to have_blacklight_label('keywords_tesim')
    expect(page).to have_blacklight_label('subtitle_tesim')
    expect(page).to have_blacklight_label('rights_tesim')
    expect(page).to have_blacklight_label('description_tesim')
    expect(page).to have_blacklight_label('resource_type_tesim')
    expect(page).to have_blacklight_label('contributor_tesim')
    expect(page).to have_blacklight_label('publisher_tesim')
    expect(page).to have_blacklight_label('published_date_tesim')
    expect(page).to have_blacklight_label('subject_tesim')
    expect(page).to have_blacklight_label('language_tesim')
    expect(page).to have_blacklight_label('identifier_tesim')
    expect(page).to have_blacklight_label('based_near_tesim')
    expect(page).to have_blacklight_label('related_url_tesim')
    expect(page).to have_blacklight_label('source_tesim')
    expect(page).to have_blacklight_label('version_number_isi')
    expect(page).to have_blacklight_label('created_at_dtsi')
    expect(page).to have_blacklight_label('updated_at_dtsi')

    expect(page).to have_blacklight_field('title_tesim').with(record[:title])
    expect(page).to have_blacklight_field('aasm_state_tesim').with(record[:state])
    expect(page).to have_blacklight_field('keywords_tesim').with(record[:keywords].join(', '))
    expect(page).to have_blacklight_field('subtitle_tesim').with(record[:subtitle])
    expect(page).to have_blacklight_field('rights_tesim').with(record[:rights])
    expect(page).to have_blacklight_field('description_tesim').with(record[:description].join(', '))
    expect(page).to have_blacklight_field('resource_type_tesim').with(record[:resource_type].join(', '))
    expect(page).to have_blacklight_field('contributor_tesim').with(record[:contributor].join(', '))
    expect(page).to have_blacklight_field('publisher_tesim').with(record[:publisher].join(', '))
    expect(page).to have_blacklight_field('published_date_tesim').with(record[:published_date].join(', '))
    expect(page).to have_blacklight_field('subject_tesim').with(record[:subject].join(', '))
    expect(page).to have_blacklight_field('language_tesim').with(record[:language].join(', '))
    expect(page).to have_blacklight_field('identifier_tesim').with(record[:identifier].join(', '))
    expect(page).to have_blacklight_field('based_near_tesim').with(record[:based_near].join(', '))
    expect(page).to have_blacklight_field('related_url_tesim').with(record[:related_url].join(', '))
    expect(page).to have_blacklight_field('source_tesim').with(record[:source].join(', '))
    expect(page).to have_blacklight_field('version_number_isi').with(record[:version_number])
    expect(page).to have_blacklight_field('created_at_dtsi').with(record[:created_at].iso8601)
    expect(page).to have_blacklight_field('updated_at_dtsi').with(record[:updated_at].iso8601)
  end
end
