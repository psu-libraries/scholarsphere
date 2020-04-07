# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Publishing a new work' do
  let(:user) { create(:user) }
  let(:metadata) { attributes_for(:work_version, :with_complete_metadata) }
  let(:updated_metadata) { attributes_for(:work_version, :with_complete_metadata) }

  it 'routes the user through the workflow', with_user: :user, js: true do
    visit(new_dashboard_work_path)
    fill_in('Title', with: metadata[:title])
    click_button('Create Work')
    expect(page).to have_selector('h1', text: 'Your ScholarSphere Deposits')
    within('.work-list') do
      expect(page).to have_selector('h3', text: metadata[:title])
    end
    within('.work-version') do
      expect(page).to have_link('Version 1')
      within('.badge') { expect(page).to have_text('draft') }
      click_link('edit')
    end

    # Wait for Uppy to load
    while page.has_no_selector?('.uppy-DashboardAddFiles')
      sleep 0.1
    end

    within('.uppy-DashboardAddFiles') do
      expect(page).to have_content('Drop files here, paste or browse')
    end

    attach_file 'files[]', (Rails.root + 'spec/fixtures/image.png').to_s, make_visible: true

    # Wait for file to finish uploading
    while page.has_no_selector?('.uppy-DashboardContent-title', text: 'Upload complete')
      sleep 0.1
    end

    within('.uppy-Dashboard-files') do
      expect(page).to have_content('image.png')
    end

    click_button('Save and Continue')

    # Ensure one creator is pre-filled with the User's Actor
    within('#creator_aliases') do
      actor = user.reload.actor
      expect(find_field('Display Name').value).to eq actor.default_alias
      expect(find_field('Email').value).to eq actor.email
      expect(find_field('Given name').value).to eq actor.given_name
      expect(find_field('Surname').value).to eq actor.surname
      expect(find_field('PSU ID').value).to eq actor.psu_id
    end

    fill_in('Subtitle', with: metadata[:subtitle])
    fill_in('Keywords', with: metadata[:keyword].first)
    fill_in('Rights', with: metadata[:rights])
    fill_in('Description', with: metadata[:description])
    fill_in('Resource Type', with: metadata[:resource_type])
    fill_in('Contributor', with: metadata[:contributor])
    fill_in('Publisher', with: metadata[:publisher])
    fill_in('Published Date', with: metadata[:published_date])
    fill_in('Subject', with: metadata[:subject])
    fill_in('Language', with: metadata[:language])
    fill_in('Identifier', with: metadata[:identifier])
    fill_in('Based Near', with: metadata[:based_near])
    fill_in('Related URL', with: metadata[:related_url])
    fill_in('Source', with: metadata[:source])

    # Rename "my" creator
    within('#creator_aliases .nested-fields:nth-of-type(1)') do
      fill_in('Display Name', with: 'MY EDITED CREATOR NAME')
    end

    retry_click { click_link('Add another Creator') }

    # Add another creator
    within('#creator_aliases .nested-fields:nth-of-type(2)') do
      fill_in('Display Name', with: 'Dr. Second Creator, PhD.')
      fill_in('Email', with: '2nd.creator@example.com')
      fill_in('Given name', with: 'Second')
      fill_in('Surname', with: 'Creator')
    end

    click_button('Save and Continue')

    expect(page).to have_selector('h1', text: 'Publishing Work Version')
    check('I agree to all the stuff I need to to make this work')
    click_button('Publish')

    expect(page).to have_selector('h1', text: 'Your ScholarSphere Deposits')
    within('.work-list') do
      expect(page).to have_selector('h3', text: metadata[:title])
    end
    within('.work-version') do
      expect(page).to have_link('Version 1')
      expect(page).not_to have_link('edit')
      within('.badge') { expect(page).to have_text('published') }
      click_link('new version')
    end

    within('.table') do
      expect(page).to have_content('image.png')
      expect(page).to have_content('62.5 KB')
      expect(page).to have_content('image/png')
    end

    # Re-upload the same file again
    attach_file 'files[]', (Rails.root + 'spec/fixtures/image.png').to_s, make_visible: true

    within('.uppy-Informer') do
      until page.has_content?('Error: image.png already exists in this version')
        sleep 0.1
      end
    end

    click_button('Save and Continue')

    expect(page).to have_field('Subtitle', with: metadata[:subtitle])
    expect(page).to have_field('Keywords', with: metadata[:keyword].first)
    expect(page).to have_field('Rights', with: metadata[:rights])
    expect(page).to have_field('Description', with: metadata[:description])
    expect(page).to have_field('Resource Type', with: metadata[:resource_type])
    expect(page).to have_field('Contributor', with: metadata[:contributor])
    expect(page).to have_field('Publisher', with: metadata[:publisher])
    expect(page).to have_field('Published Date', with: metadata[:published_date])
    expect(page).to have_field('Subject', with: metadata[:subject])
    expect(page).to have_field('Language', with: metadata[:language])
    expect(page).to have_field('Identifier', with: metadata[:identifier])
    expect(page).to have_field('Based Near', with: metadata[:based_near])
    expect(page).to have_field('Related URL', with: metadata[:related_url])
    expect(page).to have_field('Source', with: metadata[:source])

    within('#creator_aliases .nested-fields:nth-of-type(1)') do
      expect(page).to have_field('Display Name', with: 'MY EDITED CREATOR NAME')
    end

    within('#creator_aliases .nested-fields:nth-of-type(2)') do
      expect(page).to have_field('Display Name', with: 'Dr. Second Creator, PhD.')
      expect(page).to have_field('Email', with: '2nd.creator@example.com')
      expect(page).to have_field('Given name', with: 'Second')
      expect(page).to have_field('Surname', with: 'Creator')
    end

    fill_in('Title', with: updated_metadata[:title])
    click_button('Save and Continue')

    expect(page).to have_selector('h1', text: 'Publishing Work Version')
    check('I agree to all the stuff I need to to make this work')
    click_button('Publish')

    expect(page).to have_selector('h1', text: 'Your ScholarSphere Deposits')
    within('.work-list') do
      expect(page).to have_selector('h3', text: updated_metadata[:title])
    end
    page.all('.work-version').each_with_index do |row, index|
      within(row) do
        expect(page).to have_link("Version #{index + 1}")
        within('.badge') { expect(page).to have_content('published') }
        expect(page).not_to have_link('edit')
        expect(page).not_to have_link('delete')
        if index == 0
          expect(page).not_to have_link('new version')
        else
          expect(page).to have_link('new version')
        end
      end
    end
  end
end
