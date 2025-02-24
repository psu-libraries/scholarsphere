# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Home page' do
  context 'with featured resources' do
    let!(:featured_work) { create(:featured_work) }
    let!(:featured_work_version) { create(:featured_work_version) }
    let!(:featured_collection) { create(:featured_collection) }

    it 'displays the landing page with selected featured works' do
      visit(root_path)

      expect(page).to have_css('meta[name=description]', visible: :hidden)

      within('header') do
        expect(page).to have_link('ScholarSphere')
      end

      within('nav.main-nav') do
        expect(page).to have_content('Welcome to ScholarSphere')
        expect(page).to have_no_css('button')
      end

      expect(page).to have_css('h2', text: 'Browse and search for works')
      expect(page).to have_css('h2', text: 'Featured Works')

      within('div.search') do
        expect(page).to have_css('form')
        expect(page).to have_link('Browse & Filter All Works')
      end

      expect(page).to have_css('h3', text: featured_work.resource.latest_published_version.title)
      expect(page).to have_css('h3', text: featured_work_version.resource.title)
      expect(page).to have_css('h3', text: featured_collection.resource.title)

      within('footer') do
        expect(page).to have_css('h3', text: 'ScholarSphere')
        expect(page).to have_content(I18n.t!('footer.description'))
        expect(page).to have_content('Copyright')
        expect(page).to have_link('Penn State')
        expect(page).to have_link('University Libraries')
        expect(page).to have_link('Accessibility')
      end
    end
  end

  context 'with NO featured resources' do
    it 'displays the landing page without any featured resources' do
      visit(root_path)

      expect(page).to have_css('h2', text: 'Browse and search for works')
      expect(page).to have_no_css('h2', text: 'Featured Works')
    end
  end
end
