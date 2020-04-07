# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Editing multiple fields' do
  let(:user) { create(:user) }
  let(:work) { create(:work, depositor: user.actor, has_draft: true) }
  let(:attributes_1) { attributes_for(:work_version, :with_complete_metadata) }
  let(:attributes_2) { attributes_for(:work_version, :with_complete_metadata) }

  def parent_div(field)
    find("label[for='work_version_#{field}']").first(:xpath, './/..')
  end

  context 'when adding new fields for entry' do
    def check_field(field, label: nil)
      label ||= field.to_s.titleize
      within(parent_div(field)) do
        expect(page).to have_selector('button', text: /Add another/)
        expect(page).not_to have_selector('button', text: 'Remove')
        expect(page).to have_selector('div', class: 'input-group', count: 1)
        retry_click { click_button(label) }
        expect(page).to have_selector('div', class: 'input-group', count: 2)
        retry_click { click_button('Remove') }
        expect(page).to have_selector('div', class: 'input-group', count: 1)
      end
    end

    it 'inserts new inputs with remove buttons', with_user: :user, js: true do
      visit(edit_dashboard_work_version_path(work.latest_version))
      check_field(:keyword)
      check_field(:description)
      check_field(:resource_type)
      check_field(:contributor)
      check_field(:publisher)
      check_field(:published_date)
      check_field(:subject)
      check_field(:language)
      check_field(:identifier)
      check_field(:based_near)
      check_field(:related_url, label: 'Related URL')
      check_field(:source)
    end
  end

  context 'when entering information into multiple fields' do
    def fill_in_multiple(field)
      within(parent_div(field)) do
        fill_in("work_version[#{field}][]", with: attributes_1[field])
        retry_click { find('button').click }
        expect(page.all('.form-control').last.value).to be_empty
        page.all('.form-control').last.set(attributes_2[field])
      end
    end

    def verify_multiple(field)
      within(parent_div(field)) do
        page.all('.form-control').each_with_index do |input, index|
          expect(input.value).to eq(send("attributes_#{index + 1}")[field])
        end
      end
    end

    it 'updates each field with the new information', with_user: :user, js: true do
      visit(edit_dashboard_work_version_path(work.latest_version))
      fill_in_multiple(:keyword)
      fill_in_multiple(:description)
      fill_in_multiple(:resource_type)
      fill_in_multiple(:contributor)
      fill_in_multiple(:publisher)
      fill_in_multiple(:published_date)
      fill_in_multiple(:subject)
      fill_in_multiple(:language)
      fill_in_multiple(:identifier)
      fill_in_multiple(:based_near)
      fill_in_multiple(:related_url)
      fill_in_multiple(:source)

      click_button('Save and Continue')
      visit(edit_dashboard_work_version_path(work.latest_version))

      verify_multiple(:keyword)
      verify_multiple(:description)
      verify_multiple(:resource_type)
      verify_multiple(:contributor)
      verify_multiple(:publisher)
      verify_multiple(:published_date)
      verify_multiple(:subject)
      verify_multiple(:language)
      verify_multiple(:identifier)
      verify_multiple(:based_near)
      verify_multiple(:related_url)
      verify_multiple(:source)
    end
  end
end
