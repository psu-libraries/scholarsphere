# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Work Settings Page', with_user: :user do
  let(:user) { create :user }
  let(:work) { create :work, versions_count: 1, has_draft: false, depositor: user.actor }

  it 'is available from the resource page' do
    visit resource_path(work.uuid)
    click_on I18n.t('resources.settings_button.text')
    expect(page).to have_content(I18n.t('dashboard.works.edit.heading', work_title: work.latest_version.title))
  end

  describe 'Updating visibility' do
    before do
      work.update(visibility: Permissions::Visibility::OPEN)
      visit edit_dashboard_work_path(work)
    end

    it 'works from the Settings page' do
      authorized_checkbox_label = Permissions::Visibility.display(
        Permissions::Visibility::AUTHORIZED
      )

      choose authorized_checkbox_label
      click_button I18n.t('dashboard.works.edit.visibility.submit_button')

      expect(page).to have_content(I18n.t('dashboard.works.edit.heading', work_title: work.latest_version.title))

      work.reload
      expect(work.visibility).to eq Permissions::Visibility::AUTHORIZED
    end
  end

  describe 'Updating Embargo' do
    before do
      work.update(embargoed_until: nil)
      visit edit_dashboard_work_path(work)
    end

    it 'works from the Settings page' do
      fill_in 'embargo_form_embargoed_until', with: '2030-11-11'
      click_button I18n.t('dashboard.works.edit.embargo.submit_button')

      expect(page).to have_content(I18n.t('dashboard.works.edit.heading', work_title: work.latest_version.title))

      work.reload
      expect(work.embargoed_until).to be_within(1.minute).of(Time.zone.local(2030, 11, 11, 0))

      click_button I18n.t('dashboard.works.edit.embargo.remove_button')

      work.reload
      expect(work.embargoed_until).to be_nil
    end
  end

  describe 'Minting a DOI' do
    before do
      work.update(doi: nil)
      visit edit_dashboard_work_path(work)
    end

    context 'when the work has been published' do
      let(:work) { create :work, versions_count: 1, has_draft: false, depositor: user.actor }

      it 'works from the Settings page' do
        click_button I18n.t('resources.doi.create')

        expect(page).to have_current_path(edit_dashboard_work_path(work))
        expect(page).not_to have_button I18n.t('resources.doi.create')
      end
    end

    context 'when the work has not yet been published' do
      let(:work) { create :work, versions_count: 1, has_draft: true, depositor: user.actor }

      it 'is not allowed' do
        expect(page).not_to have_content I18n.t('resources.doi.create')
        expect(page).to have_content I18n.t('dashboard.works.edit.doi.not_allowed')
      end
    end
  end

  describe 'Updating Editors' do
    context 'when adding a new editor' do
      let(:work) { create :work, depositor: user.actor }

      it 'adds a user as an editor' do
        visit edit_dashboard_work_path(work)

        expect(work.edit_users).to be_empty
        fill_in('Edit users', with: 'agw13')
        click_button('Update Editors')

        work.reload
        expect(work.edit_users.map(&:uid)).to contain_exactly('agw13')
      end
    end

    context 'when removing an existing editor' do
      let(:editor) { create(:user) }
      let(:work) { create :work, depositor: user.actor, edit_users: [editor] }

      it 'adds a user as an editor' do
        visit edit_dashboard_work_path(work)

        expect(work.edit_users).to contain_exactly(editor)
        fill_in('Edit users', with: '')
        click_button('Update Editors')

        work.reload
        expect(work.edit_users).to be_empty
      end
    end

    context 'when the user does not exist' do
      let(:work) { create :work, depositor: user.actor }

      it 'adds a user as an editor' do
        visit edit_dashboard_work_path(work)

        fill_in('Edit users', with: 'iamnotpennstate')
        click_button('Update Editors')

        work.reload
        expect(work.edit_users).to be_empty
      end
    end

    context 'when selecting a group' do
      let(:user) { create(:user, groups: User.default_groups + [group]) }
      let(:group) { create(:group) }
      let(:work) { create :work, depositor: user.actor }

      it 'adds the group as an editor' do
        visit edit_dashboard_work_path(work)

        expect(work.edit_groups).to be_empty
        select(group.name, from: 'Edit groups')
        click_button('Update Editors')

        work.reload
        expect(work.edit_groups).to contain_exactly(group)
      end
    end
  end
end
