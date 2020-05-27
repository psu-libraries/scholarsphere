# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating and managing a collection' do
  let(:user) { create :user }

  let(:existing_collection) { create :collection, :with_complete_metadata, depositor: user.actor, works: [user_work_1] }

  let(:metadata) { attributes_for :collection, :with_complete_metadata }
  let(:updated_metadata) { attributes_for :collection, :with_complete_metadata }

  let!(:user_work_1) { create :work, has_draft: false, depositor: user.actor }
  let!(:user_work_2) { create :work, has_draft: false, depositor: user.actor }
  let!(:other_work) { create :work }

  it 'creates a collection', with_user: :user, js: true do
    visit(dashboard_collections_path)
    click_on('New Collection')

    fill_in('Title', with: metadata[:title])

    # Select some works for this collection
    expect(page).to have_unchecked_field(user_work_1.latest_version.title)
    expect(page).to have_unchecked_field(user_work_2.latest_version.title)
    expect(page).not_to have_unchecked_field(other_work.latest_version.title)
    expect(page).not_to have_checked_field(other_work.latest_version.title)
    check user_work_1.latest_version.title

    fill_in('Subtitle', with: metadata[:subtitle])
    fill_in('Keywords', with: metadata[:keyword].first)
    fill_in('Description', with: metadata[:description].first)
    fill_in('Contributor', with: metadata[:contributor].first)
    fill_in('Publisher', with: metadata[:publisher].first)
    fill_in('Published Date', with: metadata[:published_date])
    fill_in('Subject', with: metadata[:subject].first)
    fill_in('Language', with: metadata[:language].first)
    fill_in('Identifier', with: metadata[:identifier].first)
    fill_in('Based Near', with: metadata[:based_near].first)
    fill_in('Related URL', with: metadata[:related_url].first)
    fill_in('Source', with: metadata[:source].first)

    # Ensure one creator is pre-filled with the User's Actor
    within('#creator_aliases') do
      actor = user.reload.actor
      expect(find_field('Display Name').value).to eq actor.default_alias
      expect(find_field('Email').value).to eq actor.email
      expect(find_field('Given name').value).to eq actor.given_name
      expect(find_field('Surname').value).to eq actor.surname
      expect(find_field('PSU ID').value).to eq actor.psu_id
    end

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

    click_button 'Create Collection'

    # Ensure record was saved to the db correctly
    user.actor.deposited_collections.last.tap do |collection|
      # Metadata
      expect(collection.title).to eq metadata[:title]
      expect(collection.subtitle).to eq metadata[:subtitle]
      expect(collection.keyword).to eq [metadata[:keyword].first]
      expect(collection.description).to eq [metadata[:description].first]
      expect(collection.contributor).to eq [metadata[:contributor].first]
      expect(collection.publisher).to eq [metadata[:publisher].first]
      expect(collection.published_date).to eq metadata[:published_date]
      expect(collection.subject).to eq [metadata[:subject].first]
      expect(collection.language).to eq [metadata[:language].first]
      expect(collection.identifier).to eq [metadata[:identifier].first]
      expect(collection.based_near).to eq [metadata[:based_near].first]
      expect(collection.related_url).to eq [metadata[:related_url].first]
      expect(collection.source).to eq [metadata[:source].first]

      # Creators
      expect(collection.creator_aliases.map(&:alias))
        .to contain_exactly('MY EDITED CREATOR NAME', 'Dr. Second Creator, PhD.')

      # Works
      expect(collection.works).to contain_exactly(user_work_1)
    end
  end

  it 'shows a collection', with_user: :user do
    existing_collection # pop this into existence
    visit dashboard_collections_path

    expect(page).to have_content(existing_collection.title)

    click_link('Show')

    expect(page).to have_content(existing_collection.title)
    expect(page).to have_content(existing_collection.subtitle)
    expect(page).to have_content(user_work_1.latest_version.title)
  end

  it 'edits a collection', with_user: :user do
    existing_collection # pop this into existence
    visit dashboard_collections_path

    expect(page).to have_content(existing_collection.title)

    click_link('Edit')

    fill_in('Title', with: updated_metadata[:title])
    uncheck user_work_1.latest_version.title
    check user_work_2.latest_version.title
    click_button 'Update Collection'

    # Ensure record was saved to the db correctly
    existing_collection.reload
    expect(existing_collection.title).to eq updated_metadata[:title]

    # Works
    expect(existing_collection.works).to contain_exactly(user_work_2)
  end

  it 'deletes a collection', with_user: :user do
    existing_collection # pop this into existence
    visit dashboard_collections_path

    expect(page).to have_content(existing_collection.title)

    click_link('Delete')

    expect { existing_collection.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
