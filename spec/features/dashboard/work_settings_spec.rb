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
end
