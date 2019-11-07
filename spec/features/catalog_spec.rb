# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Blacklight catalog page' do
  let(:user) { create(:user) }

  let!(:works) do
    Array.new(10).map do
      FactoryBot.create(:work, depositor: user, versions_count: rand(1..5), has_draft: true)
    end
  end

  let(:titles) do
    works.map { |work| work.latest_version.title }
  end

  it 'displays the search form and facets' do
    visit search_catalog_path
    click_button('Search')
    expect(page).to have_content("1 - 10 of #{WorkVersion.count}")
    expect(page).to have_selector('h3', text: 'Status')
    click_link('100 per page')
    titles.each do |title|
      expect(page).to have_content(title)
    end
  end
end
