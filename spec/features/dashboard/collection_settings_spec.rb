# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Collection Settings Page', with_user: :user do
  let(:user) { create :user }
  let(:collection) { create :collection, depositor: user.actor }

  it 'is available from the resource page' do
    visit resource_path(collection.uuid)
    click_on I18n.t('resources.settings_button.text', type: 'Collection')
    expect(page).to have_content(I18n.t('dashboard.collections.edit.heading', title: collection.title))
  end

  describe 'Minting a DOI' do
    before do
      collection.update(doi: nil)
      visit edit_dashboard_collection_path(collection)
    end

    it 'works from the Settings page' do
      click_button I18n.t('resources.doi.create')

      expect(page).to have_current_path(edit_dashboard_collection_path(collection))
      expect(page).not_to have_button I18n.t('resources.doi.create')
    end
  end

  describe 'Updating Editors', :vcr do
    context 'when adding a new editor' do
      it 'adds a user as an editor' do
        visit edit_dashboard_collection_path(collection)

        expect(collection.edit_users).to be_empty
        fill_in('Edit users', with: 'agw13')
        click_button('Update Editors')

        collection.reload
        expect(collection.edit_users.map(&:uid)).to contain_exactly('agw13')
      end
    end

    context 'when removing an existing editor' do
      let(:editor) { create(:user) }
      let(:collection) { create :collection, depositor: user.actor, edit_users: [editor] }

      it 'adds a user as an editor' do
        visit edit_dashboard_collection_path(collection)

        expect(collection.edit_users).to contain_exactly(editor)
        fill_in('Edit users', with: '')
        click_button('Update Editors')

        collection.reload
        expect(collection.edit_users).to be_empty
      end
    end

    context 'when the user does not exist' do
      let(:collection) { create :collection, depositor: user.actor }

      it 'adds a user as an editor' do
        visit edit_dashboard_collection_path(collection)

        fill_in('Edit users', with: 'iamnotpennstate')
        click_button('Update Editors')

        collection.reload
        expect(collection.edit_users).to be_empty
      end
    end

    context 'when selecting a group' do
      let(:user) { create(:user, groups: User.default_groups + [group]) }
      let(:group) { create(:group) }
      let(:collection) { create :collection, depositor: user.actor }

      it 'adds the group as an editor' do
        visit edit_dashboard_collection_path(collection)

        expect(collection.edit_groups).to be_empty
        select(group.name, from: 'Edit groups')
        click_button('Update Editors')

        collection.reload
        expect(collection.edit_groups).to contain_exactly(group)
      end
    end
  end
end
