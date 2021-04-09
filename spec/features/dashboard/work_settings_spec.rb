# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Work Settings Page', with_user: :user do
  let(:user) { create :user }
  let(:work) { create :work, versions_count: 1, has_draft: false, depositor: user.actor }

  before do
    mock_solr_indexing_job
  end

  # When stepping through each page of the form, we want to test whether the
  # collection was indexed, and how, based on the buttons that were pressed.
  # Because there can be multiple of these steps within each test, and because
  # RSpec mocks _cumulatively_ record the number of times they've been called,
  # we need a way to say "from this exact point, you should have been called
  # once." We accomplish this by tearing down the mock and setting it back up.
  def mock_solr_indexing_job
    RSpec::Mocks.space.proxy_for(SolrIndexingJob)&.reset

    allow(SolrIndexingJob).to receive(:perform_now).and_call_original
    allow(SolrIndexingJob).to receive(:perform_later).and_call_original
  end

  it 'is available from the resource page' do
    visit resource_path(work.uuid)
    click_on I18n.t('resources.settings_button.text', type: 'Work')
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
      mock_solr_indexing_job
      click_button I18n.t('dashboard.works.edit.visibility.submit_button')

      expect(page).to have_content(I18n.t('dashboard.works.edit.heading', work_title: work.latest_version.title))

      work.reload
      expect(work.visibility).to eq Permissions::Visibility::AUTHORIZED
      expect(SolrIndexingJob).to have_received(:perform_later).once
    end
  end

  describe 'Updating Embargo' do
    before do
      work.update(embargoed_until: nil)
      visit edit_dashboard_work_path(work)
    end

    it 'works from the Settings page' do
      fill_in 'embargo_form_embargoed_until', with: '2030-11-11'
      mock_solr_indexing_job
      click_button I18n.t('dashboard.works.edit.embargo.submit_button')
      expect(SolrIndexingJob).to have_received(:perform_later).once

      expect(page).to have_content(I18n.t('dashboard.works.edit.heading', work_title: work.latest_version.title))

      work.reload
      expect(work.embargoed_until).to be_within(1.minute).of(Time.zone.local(2030, 11, 11, 0))

      mock_solr_indexing_job
      click_button I18n.t('dashboard.works.edit.embargo.remove_button')

      work.reload
      expect(work.embargoed_until).to be_nil
      expect(SolrIndexingJob).to have_received(:perform_later).once
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

  describe 'Updating Editors', :vcr do
    context 'when adding a new editor' do
      let(:work) { create :work, depositor: user.actor }

      it 'adds a user as an editor' do
        visit edit_dashboard_work_path(work)

        expect(work.edit_users).to be_empty
        fill_in('Edit users', with: 'agw13')
        mock_solr_indexing_job
        click_button('Update Editors')

        work.reload
        expect(work.edit_users.map(&:uid)).to contain_exactly('agw13')
        expect(SolrIndexingJob).to have_received(:perform_later).once
      end
    end

    context 'when removing an existing editor' do
      let(:editor) { create(:user) }
      let(:work) { create :work, depositor: user.actor, edit_users: [editor] }

      it 'adds a user as an editor' do
        visit edit_dashboard_work_path(work)

        expect(work.edit_users).to contain_exactly(editor)
        fill_in('Edit users', with: '')
        mock_solr_indexing_job
        click_button('Update Editors')

        work.reload
        expect(work.edit_users).to be_empty
        expect(SolrIndexingJob).to have_received(:perform_later).once
      end
    end

    context 'when the user does not exist' do
      let(:work) { create :work, depositor: user.actor }

      it 'does NOT add the user as an editor' do
        visit edit_dashboard_work_path(work)

        fill_in('Edit users', with: 'iamnotpennstate')
        mock_solr_indexing_job
        click_button('Update Editors')

        work.reload
        expect(work.edit_users).to be_empty
        expect(SolrIndexingJob).not_to have_received(:perform_later)
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
        mock_solr_indexing_job
        click_button('Update Editors')

        work.reload
        expect(work.edit_groups).to contain_exactly(group)
        expect(SolrIndexingJob).to have_received(:perform_later).once
      end
    end
  end

  describe 'Deleting a work' do
    context 'when a regular user' do
      it 'does not allow a regular user to delete a work version' do
        visit edit_dashboard_work_path(work)
        expect(page).not_to have_content(I18n.t!('dashboard.works.edit.danger.explanation'))
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
end
