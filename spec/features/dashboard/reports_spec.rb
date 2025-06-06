# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Reports', with_user: :user do
  context 'with a standard user' do
    let(:user) { create(:user) }

    it 'only shows the monthly user report' do
      visit dashboard_reports_path
      display_name = "#{user.name} (#{user.access_id})"

      expect(page).to have_no_css('h2', text: I18n.t('dashboard.reports.admin_reports'))
      expect(page).to have_no_css('h3 a', text: I18n.t('dashboard.reports.all_files_report'))
      expect(page).to have_no_css('h3 a', text: I18n.t('dashboard.reports.all_works_report'))
      expect(page).to have_no_css('h3 a', text: I18n.t('dashboard.reports.all_work_versions_report'))
      expect(page).to have_no_css('h3', text: I18n.t('dashboard.reports.monthly_report'))
      expect(page).to have_css('h3', text: I18n.t('dashboard.reports.user_report.heading', user: display_name))
    end
  end

  context 'with an admin user' do
    let(:user) { create(:user, :admin) }

    it 'shows all reports' do
      visit dashboard_reports_path
      expect(page).to have_css('h2', text: I18n.t('dashboard.reports.admin_reports'))
      expect(page).to have_css('h3 a', text: I18n.t('dashboard.reports.all_files_report'))
      expect(page).to have_css('h3 a', text: I18n.t('dashboard.reports.all_works_report'))
      expect(page).to have_css('h3 a', text: I18n.t('dashboard.reports.all_work_versions_report'))
      expect(page).to have_css('h3', text: I18n.t('dashboard.reports.monthly_report'))
      expect(page).to have_css('h3', text: I18n.t('dashboard.reports.user_report.heading', user: 'Administrator'))
    end
  end
end
