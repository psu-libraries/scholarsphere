# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Setting visibility in the dashboard', with_user: :user do
  let(:user) { work_version.work.depositor.user }

  context 'when changing from public to Penn State' do
    let(:work_version) { create :work_version, :able_to_be_published }

    it 'sets the visibility to Penn State' do
      visit dashboard_form_publish_path(work_version)

      expect(find_field('Public')).to be_checked

      choose "work_version_work_attributes_visibility_#{Permissions::Visibility::AUTHORIZED}"
      check 'work_version_depositor_agreement'
      FeatureHelpers::DashboardForm.publish

      work = Work.last
      expect(work).to be_authorized_access
    end
  end

  context 'when changing from Penn State to public' do
    let(:work_version) { create :work_version, :able_to_be_published, work: create(:work, :with_authorized_access) }

    it 'sets the visibility to public' do
      visit dashboard_form_publish_path(work_version)

      expect(find_field('Penn State Only')).to be_checked

      choose "work_version_work_attributes_visibility_#{Permissions::Visibility::OPEN}"
      check 'work_version_depositor_agreement'
      FeatureHelpers::DashboardForm.publish

      work = Work.last
      expect(work).to be_open_access
    end
  end

  context 'when changing from restricted to Penn State' do
    let(:work_version) { create :work_version, :able_to_be_published, work: create(:work, :with_no_access) }

    it 'sets the visibility to public' do
      visit dashboard_form_publish_path(work_version)

      expect(find_field('Penn State Only')).not_to be_checked
      expect(find_field('Public')).not_to be_checked

      choose "work_version_work_attributes_visibility_#{Permissions::Visibility::AUTHORIZED}"
      check 'work_version_depositor_agreement'
      FeatureHelpers::DashboardForm.publish

      work = Work.last
      expect(work).to be_authorized_access
    end
  end

  context 'when changing from restricted to public' do
    let(:work_version) { create :work_version, :able_to_be_published, work: create(:work, :with_no_access) }

    it 'sets the visibility to public' do
      visit dashboard_form_publish_path(work_version)

      expect(find_field('Penn State Only')).not_to be_checked
      expect(find_field('Public')).not_to be_checked

      choose "work_version_work_attributes_visibility_#{Permissions::Visibility::OPEN}"
      check 'work_version_depositor_agreement'
      FeatureHelpers::DashboardForm.publish

      work = Work.last
      expect(work).to be_open_access
    end
  end

  context 'when NOT changing from restricted' do
    let(:work_version) { create :work_version, :able_to_be_published, work: create(:work, :with_no_access) }

    it 'sets the visibility to public' do
      visit dashboard_form_publish_path(work_version)

      expect(find_field('Penn State Only')).not_to be_checked
      expect(find_field('Public')).not_to be_checked

      check 'work_version_depositor_agreement'
      FeatureHelpers::DashboardForm.publish

      within('#error_explanation') do
        expect(page).to have_content('Access cannot be private')
      end
    end
  end
end
