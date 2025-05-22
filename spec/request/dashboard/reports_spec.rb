# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::ReportsController, type: :request do
  let(:user) { create(:user) }
  let(:today) { Date.today }
  let(:one_month_ago) { 1.month.ago }
  let(:report_start_date_params) do
    {
      year: one_month_ago.year,
      month: one_month_ago.month,
      day: one_month_ago.day
    }
  end
  let(:report_end_date_params) do
    {
      year: today.year,
      month: today.month,
      day: today.day
    }
  end

  describe 'GET #user_work_versions' do
    context 'when the user is signed in' do
      before do
        sign_in user
        get dashboard_reports_user_work_versions_path, params: {
          report_start_date: report_start_date_params,
          report_end_date: report_end_date_params
        }
      end

      context 'when the user enters an invalid date' do
        let(:report_start_date_params) do
          {
            year: 2000,
            month: 2,
            day: 31
          }
        end

        it 're-renders the report list and shows an error message' do
          expect(response).to have_http_status :ok
          expect(response.body).to include 'Report Start Date'
          expect(response.body).to include 'You entered an invalid date'
        end
      end

      context 'when the user enters an end date that is before the start date' do
        let(:report_end_date_params) do
          {
            year: 2000,
            month: 1,
            day: 1
          }
        end

        it 're-renders the report list and shows an error message' do
          expect(response).to have_http_status :ok
          expect(response.body).to include 'Report Start Date'
          expect(response.body).to include 'You entered an end date that is before the start date'
        end
      end

      context 'when the user enters a end date that is in the future' do
        let(:report_end_date_params) do
          {
            year: 1.year.from_now.year,
            month: 1.year.from_now.month,
            day: 1.year.from_now.day
          }
        end

        it 're-renders the report list and shows an error message' do
          expect(response).to have_http_status :ok
          expect(response.body).to include 'Report Start Date'
          expect(response.body).to include 'You entered a date that is in the future'
        end
      end
    end
  end
end
