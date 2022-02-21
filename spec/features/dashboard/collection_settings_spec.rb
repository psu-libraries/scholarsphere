# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Collection Settings Page', with_user: :user do
  let(:user) { create :user }
  let(:collection) { create :collection, depositor: user.actor }

  it 'is available from the resource page' do
    visit resource_path(collection.uuid)
    click_on I18n.t!('resources.settings_button.text', type: 'Collection')
    expect(page).to have_content(I18n.t!('dashboard.collections.edit.heading', title: collection.title))
  end

  describe 'Minting a DOI' do
    before do
      collection.update(doi: nil)
      visit edit_dashboard_collection_path(collection)
    end

    it 'works from the Settings page' do
      click_button I18n.t!('resources.doi.create')

      expect(page).to have_current_path(edit_dashboard_collection_path(collection))
      expect(page).not_to have_button I18n.t!('resources.doi.create')
    end
  end

  describe 'Updating thumbnail settings' do
    describe 'toggling auto-generate thumbnail' do
      context 'when no thumbnail exists for the collection' do
        before do
          visit edit_dashboard_collection_path(collection)
        end

        it 'does not display auto-generate thumbnail section' do
          expect(page)
            .not_to have_content I18n.t!('dashboard.shared.thumbnail_form.auto_generate_thumbnail.explanation')
        end
      end

      context 'when thumbnail exists for the collection' do
        before do
          allow_any_instance_of(Collection).to receive(:thumbnail_present?).and_return true
          allow_any_instance_of(Collection).to receive(:auto_generated_thumbnail_url).and_return 'url.com/path/file'
          visit edit_dashboard_collection_path(collection)
        end

        it 'works from the Settings page' do
          check(I18n.t!('dashboard.shared.thumbnail_form.auto_generate_thumbnail.explanation'), allow_label_click: true)
          expect(page).to have_content(I18n.t!('helpers.hint.thumbnail_form.auto_generate_thumbnail'))
          expect(page).to have_xpath('//img[@src="url.com/path/file"]')
          click_button I18n.t!('dashboard.shared.thumbnail_form.submit_button')
          expect(page)
            .to have_checked_field(I18n.t!('dashboard.shared.thumbnail_form.auto_generate_thumbnail.explanation'))

          collection.reload
          expect(collection.auto_generate_thumbnail).to eq true

          uncheck(I18n.t!('dashboard.shared.thumbnail_form.auto_generate_thumbnail.explanation'),
                  allow_label_click: true)
          click_button I18n.t!('dashboard.shared.thumbnail_form.submit_button')
          expect(page)
            .to have_no_checked_field(I18n.t!('dashboard.shared.thumbnail_form.auto_generate_thumbnail.explanation'))

          collection.reload
          expect(collection.auto_generate_thumbnail).to eq false
        end
      end
    end

    describe 'uploading and deleting a thumbnail', js: true do
      before do
        visit edit_dashboard_collection_path(collection)
      end

      it 'uploads and deletes a thumbnail' do
        within('.edit-thumbnail') do
          FeatureHelpers::DashboardForm.upload_file(Rails.root.join('spec', 'fixtures', 'image.png'))
        end
        expect { click_button I18n.t!('dashboard.shared.thumbnail_form.submit_button') }
          .to change(ThumbnailUpload, :count).by 1
        expect(ThumbnailUpload.last.file_resource.file_data['metadata']['filename']).to eq 'image.png'
        expect(ThumbnailUpload.last.resource).to eq collection

        expect(page).to have_content('Your uploaded thumbnail:')
        expect(page).to have_content('image.png')
        within('.edit-thumbnail') do
          accept_confirm do
            click_link('Remove')
          end
        end
        sleep 0.1

        expect(ThumbnailUpload.count).to eq 0
        expect(FileResource.count).to eq 0

        expect(page).not_to have_content('Your uploaded thumbnail:')
        expect(page).not_to have_content('image.png')
      end
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

  describe 'Deleting a collection' do
    context 'when a regular user' do
      it 'does not allow a regular user to delete a collection' do
        visit edit_dashboard_collection_path(collection)
        expect(page).not_to have_content(I18n.t!('dashboard.collections.edit.danger.explanation'))
        expect(page).not_to have_link(I18n.t!('dashboard.form.actions.destroy.button'))
      end
    end

    context 'when an admin user' do
      let(:user) { create :user, :admin }

      before { collection.update!(doi: FactoryBotHelpers.datacite_doi) }

      it 'allows a collection to be deleted' do
        visit edit_dashboard_collection_path(collection)
        click_on(I18n.t!('dashboard.form.actions.destroy.button'))
        expect { collection.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'Changing the depositor' do
    context 'with a standard user' do
      it 'does not allow the change' do
        visit edit_dashboard_collection_path(collection)
        expect(page).not_to have_content(I18n.t!('dashboard.shared.depositor_form.heading'))
        expect(page).not_to have_link(I18n.t!('dashboard.shared.depositor_form.submit_button'))
      end
    end

    context 'with an admin user' do
      let(:user) { create :user, :admin }
      let(:actor) { create(:actor) }

      it 'allows the change' do
        visit edit_dashboard_collection_path(collection)
        fill_in('Access Account', with: actor.psu_id)
        click_on(I18n.t!('dashboard.shared.depositor_form.submit_button'))
        expect(page).to have_content(I18n.t!('dashboard.collections.update.success'))
        collection.reload
        expect(collection.depositor).to eq(actor)
      end
    end
  end
end
