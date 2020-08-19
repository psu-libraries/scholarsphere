# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Home page', type: :feature do
  before do
    Array.new(3).map do
      FactoryBot.create(:work, has_draft: false)
    end
  end

  it 'displays the landing page with selected featured works' do
    visit(root_path)

    within('header') do
      expect(page).to have_link('ScholarSphere')
    end

    within('nav.main-nav') do
      expect(page).to have_content('Welcome to ScholarSphere')
    end

    expect(page).to have_selector('h2', text: 'What is ScholarSphere?')
    expect(page).to have_selector('h2', text: 'Browse and search for works')
    expect(page).to have_selector('h2', text: 'Featured Works')

    within('div.search') do
      expect(page).to have_selector('form')
      expect(page).to have_link('Browse & Filter All Works')
    end

    WorkVersion.all.each do |work_version|
      expect(page).to have_selector('h3', text: work_version.title)
    end

    within('footer') do
      expect(page).to have_selector('h3', text: 'ScholarSphere')
      expect(page).to have_content('A service of the University Libraries.')
      expect(page).to have_content('Copyright')
      expect(page).to have_link('Penn State')
      expect(page).to have_link('University Libraries')
      expect(page).to have_link('Accessibility')
    end
  end
end
