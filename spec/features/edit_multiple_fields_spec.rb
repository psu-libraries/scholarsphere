# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Editing multiple fields' do
  let(:user) { create(:user) }
  let(:work) { create(:work, depositor: user.actor, has_draft: true) }
  let(:attributes_1) { attributes_for(:work_version, :with_complete_metadata) }
  let(:attributes_2) { attributes_for(:work_version, :with_complete_metadata) }

  def parent_div(field)
    find_all("input#work_version_#{field}").first.ancestor('[data-controller="multiple-fields"]')
  end

  context 'when adding new fields for entry' do
    def check_field(field)
      within(parent_div(field)) do
        expect(page).to have_selector('a.add', text: /add_circle_outline/)
        expect(page).not_to have_selector('a.remove', text: /highlight_off/)
        expect(page).to have_selector('div', class: 'removable-input', count: 1)
        retry_click { click_on 'add_circle_outline' }
        expect(page).to have_selector('div', class: 'removable-input', count: 2)
        retry_click { click_on('highlight_off') }
        expect(page).to have_selector('div', class: 'removable-input', count: 1)
      end
    end

    def fill_in_multiple(field)
      within(parent_div(field)) do
        fill_in("work_version[#{field}][]", with: attributes_1[field])
        retry_click { click_on 'add_circle_outline' }
        expect(page.all('.form-control').last.value).to be_empty
        page.all('.form-control').last.set(attributes_2[field])
      end
    end

    def verify_multiple(field)
      parent = parent_div(field)
      within(parent) do
        page.all('.form-control').each_with_index do |input, index|
          expect(input.value).to eq(send("attributes_#{index + 1}")[field])
        end
      end

      removeable_inputs = parent.find_all('div')
      removeable_inputs[0].has_content?('remove')
      removeable_inputs[1].has_content?('add another')
    end

    it 'inserts new inputs with remove buttons', with_user: :user, js: true do
      visit dashboard_form_work_version_details_path(work.latest_version)
      check_field(:keyword)
      check_field(:publisher)
      check_field(:identifier)
      check_field(:related_url)
      check_field(:subject)
      check_field(:language)
      check_field(:based_near)
      check_field(:source)

      fill_in_multiple(:keyword)
      fill_in_multiple(:publisher)
      fill_in_multiple(:identifier)
      fill_in_multiple(:related_url)
      fill_in_multiple(:subject)
      fill_in_multiple(:language)
      fill_in_multiple(:based_near)
      fill_in_multiple(:source)

      click_button('Save and Continue')
      visit dashboard_form_work_version_details_path(work.latest_version)

      verify_multiple(:keyword)
      verify_multiple(:publisher)
      verify_multiple(:identifier)
      verify_multiple(:related_url)
      verify_multiple(:subject)
      verify_multiple(:language)
      verify_multiple(:based_near)
      verify_multiple(:source)
    end
  end
end
