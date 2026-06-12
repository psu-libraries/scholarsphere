# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Search Facets', :inline_jobs do
<<<<<<< Updated upstream
=======
  describe 'display "more" modal' do
    before do
      25.times do
        create(:work, work_type: Work::Types.all.sample, versions_count: 2, has_draft: false)
      end
    end

    it 'displays the modal and exits the modal', :js do
      visit search_catalog_path
      expect(page).to have_button('search', wait: 10)
      click_button('search')

      within '#facets' do
        first('[data-target="#facet-display_work_type_ssi"]').click
      end

      click_link 'more'

      expect(page).to have_content 'Numerical Sort'

      first('[data-bl-dismiss="modal"]').click
    end
  end

>>>>>>> Stashed changes
  describe 'renaming a user updates their Creator facet' do
    let(:my_actor) { build(:actor, display_name: 'Me Before Rename') }

    let(:another_actor) { build(:actor, display_name: 'Someone Else') }

    it 'updates the facet (but not the resource) when an actor changes their default display_name' do
      pending('Requires further input from stakeholders on design and metadata changes')
      visit search_catalog_path
      expect(page).to have_button('Search', wait: 10)
      click_button('Search')

      # Sanity Check
      within '#documents' do
        expect(page).to have_content('Me Before Rename')
        expect(page).to have_content('Someone Else')
      end
      within '#facets' do
        expect(page).to have_content('Me Before Rename')
        expect(page).to have_content('Someone Else')
      end

      # Update my default display_name
      my_actor.update(display_name: 'Me After Rename')

      expect(page).to have_button('Search', wait: 10)
      click_button('Search')

      # Documents retain the original display_name from when the resource was created
      within '#documents' do
        expect(page).to have_no_content('Me After Rename')
        expect(page).to have_content('Me Before Rename')
        expect(page).to have_content('Someone Else')
      end

      # Facets are "Canonized" to the Actor's display_name
      within '#facets' do
        expect(page).to have_content('Me After Rename')
        expect(page).to have_no_content('Me Before Rename')
        expect(page).to have_content('Someone Else')
      end

      # Make sure facets actually work
      within('#facets') { click_link 'Me After Rename' }
      within '#documents' do
        expect(page).to have_content 'A Work I Created'
        expect(page).to have_content 'A Collection I Created'
        expect(page).to have_no_content 'A Work Someone Else Created'
      end
    end
  end
end
