# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Work Settings Page', with_user: :user do
  let(:user) { create :user }
  let(:work) { create :work, versions_count: 1, has_draft: false, depositor: user.actor }

  before do
    allow(WorkIndexer).to receive(:call).and_call_original
  end

  it 'is available from the resource page' do
    visit resource_path(work.uuid)
    click_on I18n.t!('resources.settings_button.text', type: 'Work')
    expect(page).to have_content(I18n.t!('dashboard.works.edit.heading', work_title: work.latest_version.title))
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
      click_button I18n.t!('dashboard.works.edit.visibility.submit_button')

      expect(page).to have_content(I18n.t!('dashboard.works.edit.heading', work_title: work.latest_version.title))

      work.reload
      expect(work.visibility).to eq Permissions::Visibility::AUTHORIZED
      expect(WorkIndexer).to have_received(:call)
    end
  end

  describe 'Updating Embargo' do
    before do
      work.update(embargoed_until: nil)
      visit edit_dashboard_work_path(work)
    end

    it 'works from the Settings page' do
      fill_in 'embargo_form_embargoed_until', with: '2030-11-11'
      click_button I18n.t!('dashboard.works.edit.embargo.submit_button')

      expect(page).to have_content(I18n.t!('dashboard.works.edit.heading', work_title: work.latest_version.title))

      work.reload
      expect(work.embargoed_until).to be_within(1.minute).of(Time.zone.local(2030, 11, 11, 0))

      click_button I18n.t!('dashboard.works.edit.embargo.remove_button')

      work.reload
      expect(work.embargoed_until).to be_nil
      expect(WorkIndexer).to have_received(:call).twice
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
        click_button I18n.t!('resources.doi.create')

        expect(page).to have_current_path(edit_dashboard_work_path(work))
        expect(page).not_to have_button I18n.t!('resources.doi.create')
      end
    end

    context 'when the work has not yet been published' do
      let(:work) { create :work, versions_count: 1, has_draft: true, depositor: user.actor }

      it 'is not allowed' do
        expect(page).not_to have_content I18n.t!('resources.doi.create')
        expect(page).to have_content I18n.t!('dashboard.works.edit.doi.not_allowed')
      end
    end
  end

  describe 'Updating Auto-generate thumbnail' do
    context 'when no thumbnail exists for the work' do
      before do
        visit edit_dashboard_work_path(work)
      end

      it 'does not display thumbnail section' do
        expect(page).not_to have_content 'Thumbnail'
      end
    end

    context 'when thumbnail exists for the work' do
      before do
        allow_any_instance_of(Work).to receive(:thumbnail_present?).and_return true
        allow_any_instance_of(Work).to receive(:auto_generated_thumbnail_url).and_return 'url.com/path/file'
        visit edit_dashboard_work_path(work)
      end

      it 'works from the Settings page' do
        check(I18n.t!('dashboard.shared.thumbnail_form.explanation'), allow_label_click: true)
        expect(page).to have_content(I18n.t!('helpers.hint.thumbnail_form.auto_generate_thumbnail'))
        expect(page).to have_xpath("//img[@src='url.com/path/file']")
        click_button I18n.t!('dashboard.shared.thumbnail_form.submit_button')
        expect(page).to have_checked_field(I18n.t!('dashboard.shared.thumbnail_form.explanation'))

        work.reload
        expect(work.auto_generate_thumbnail).to eq true

        uncheck(I18n.t!('dashboard.shared.thumbnail_form.explanation'), allow_label_click: true)
        click_button I18n.t!('dashboard.shared.thumbnail_form.submit_button')
        expect(page).to have_no_checked_field(I18n.t!('dashboard.shared.thumbnail_form.explanation'))

        work.reload
        expect(work.auto_generate_thumbnail).to eq false
      end
    end
  end

  describe 'Updating Editors', :vcr do
    context 'when adding a new editor' do
      let(:work) { create :work, depositor: user.actor }

      it 'adds a user as an editor' do
        visit edit_dashboard_work_path(work)

        expect(work.edit_users).to be_empty
        fill_in('Edit users', with: 'agw13')
        click_button('Update Editors')

        work.reload
        expect(work.edit_users.map(&:uid)).to contain_exactly('agw13')
        expect(WorkIndexer).to have_received(:call)
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
        expect(WorkIndexer).to have_received(:call)
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
        expect(WorkIndexer).to have_received(:call)
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
        expect(WorkIndexer).to have_received(:call)
      end
    end
  end

  describe 'Deleting a work' do
    context 'when a regular user' do
      it 'does not allow a regular user to delete a work version' do
        visit edit_dashboard_work_path(work)
        expect(page).not_to have_content(I18n.t!('dashboard.works.edit.danger.delete_draft.explanation'))
        expect(page).not_to have_link(I18n.t!('dashboard.form.actions.destroy.button'))
      end
    end

    context 'when an admin user' do
      let(:user) { create :user, :admin }

      it 'allows a work version to be deleted' do
        visit edit_dashboard_work_path(work)
        click_on(I18n.t!('dashboard.form.actions.destroy.button'))
        expect { work.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'Changing the depositor' do
    context 'with a standard user' do
      it 'does not allow the change' do
        visit edit_dashboard_work_path(work)
        expect(page).not_to have_content(I18n.t!('dashboard.shared.depositor_form.heading'))
        expect(page).not_to have_link(I18n.t!('dashboard.shared.depositor_form.submit_button'))
      end
    end

    context 'with an admin user' do
      let(:user) { create :user, :admin }
      let(:actor) { create(:actor) }

      it 'allows the change' do
        visit edit_dashboard_work_path(work)
        fill_in('Access Account', with: actor.psu_id)
        click_on(I18n.t!('dashboard.shared.depositor_form.submit_button'))
        expect(page).to have_content(I18n.t!('dashboard.works.update.success'))
        work.reload
        expect(work.depositor).to eq(actor)
      end
    end
  end

  describe 'Withdrawing a version' do
    context 'with a standard user' do
      it 'does not allow the change' do
        visit edit_dashboard_work_path(work)
        expect(page).not_to have_content(I18n.t!('dashboard.works.edit.danger.withdraw_versions.heading'))
        expect(page).not_to have_button(I18n.t!('dashboard.works.withdraw_versions_form.submit_button'))
      end
    end

    context 'with an admin user' do
      let(:user) { create :user, :admin }

      it 'allows the version to be withdrawn' do
        visit edit_dashboard_work_path(work)
        select('V1', from: 'withdraw_versions_form_work_version_id')
        click_button(I18n.t!('dashboard.works.withdraw_versions_form.submit_button'))
        expect(work.versions.first.reload).to be_withdrawn
      end
    end
  end
end
