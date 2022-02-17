# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::ReportsController, type: :controller do
  describe 'GET #index' do
    let(:perform_request) { get :index }

    context 'when the user is signed in' do
      before { sign_in create :user }

      it 'returns a success response' do
        expect(perform_request).to be_successful
      end
    end

    context 'when the user is not signed in' do
      it 'redirects to the root path' do
        expect(perform_request).to redirect_to root_path
      end
    end
  end

  describe 'report generation' do
    let(:today) { Date.today }
    let(:report_date_params) do
      {
        year: today.year,
        month: today.month,
        day: today.day
      }
    end
    let(:csv) { CSV.parse(response.body) }
    let(:user) { create(:user) }
    let!(:work1) { create(:work, depositor: user.actor) }
    let!(:work2) { create(:work, versions_count: 2) }

    describe 'GET #all_files' do
      before do
        sign_in user
        get :all_files
      end

      context 'when the user is not an admin' do
        subject { response }

        its(:status) { is_expected.to eq 401 }
        its(:body) { is_expected.to include(I18n.t!('errors.not_authorized.heading')) }
      end

      context 'when the user is an admin' do
        subject { response }

        let(:user) { create(:user, :admin) }

        its(:status) { is_expected.to eq 200 }
      end
    end

    describe 'GET #all_works' do
      before do
        sign_in user
        get :all_works
      end

      context 'when the user is not an admin' do
        subject { response }

        its(:status) { is_expected.to eq 401 }
        its(:body) { is_expected.to include(I18n.t!('errors.not_authorized.heading')) }
      end

      context 'when the user is an admin' do
        let(:user) { create(:user, :admin) }

        it 'returns the correct content type and filename' do
          filename = "all_works_#{today}.csv"
          expect(response.headers['Content-Type']).to eq 'text/csv'
          expect(response.headers['Content-Disposition']).to include filename
        end

        it 'returns the correct data in the CSV' do
          expect(response.status).to eq 200
          expect(csv.count).to eq 3
          expect(csv[1][0]).to eq work1.uuid
          expect(csv[2][0]).to eq work2.uuid
        end
      end
    end

    describe 'GET #all_work_versions' do
      before do
        sign_in user
        get :all_work_versions
      end

      context 'when the user is not an admin' do
        subject { response }

        its(:status) { is_expected.to eq 401 }
        its(:body) { is_expected.to include(I18n.t!('errors.not_authorized.heading')) }
      end

      context 'when the user is an admin' do
        let(:user) { create(:user, :admin) }

        it 'returns the correct content type and filename' do
          filename = "all_work_versions_#{today}.csv"
          expect(response.headers['Content-Type']).to eq 'text/csv'
          expect(response.headers['Content-Disposition']).to include filename
        end

        it 'returns the correct data in the CSV' do
          expect(response.status).to eq 200
          expect(csv.count).to eq 4
          expect(csv[1][0]).to eq work1.versions.first.uuid
          expect(csv[2][0]).to eq work2.versions.first.uuid
          expect(csv[3][0]).to eq work2.versions.last.uuid
        end
      end
    end

    describe 'GET #monthly_work_versions' do
      before do
        sign_in user
        get :monthly_work_versions, params: {
          report_date: report_date_params
        }
      end

      context 'when the user is not an admin' do
        subject { response }

        its(:status) { is_expected.to eq 401 }
        its(:body) { is_expected.to include(I18n.t!('errors.not_authorized.heading')) }
      end

      context 'when the user is an admin' do
        let(:user) { create(:user, :admin) }

        it 'returns the correct content type and filename' do
          report_month = today.strftime('%Y-%m')
          filename = "monthly_works_#{report_month}_#{today}.csv"
          expect(response.headers['Content-Type']).to eq 'text/csv'
          expect(response.headers['Content-Disposition']).to include filename
        end

        it 'returns the correct data in the CSV' do
          expect(response.status).to eq 200
          expect(csv.count).to eq 3
          expect(csv[1][0]).to eq work1.uuid
          expect(csv[2][0]).to eq work2.uuid
        end
      end
    end

    describe 'GET #monthly_user_work_versions' do
      context 'when the user is not signed in' do
        before do
          get :monthly_user_work_versions, params: {
            report_date: report_date_params
          }
        end

        it 'returns an error' do
          expect(response.status).to eq 302
          expect(response).not_to be_successful
        end
      end

      context 'when the user is signed in' do
        before do
          sign_in user
          get :monthly_user_work_versions, params: {
            report_date: report_date_params
          }
        end

        it 'returns the correct content type and filename' do
          report_month = today.strftime('%Y-%m')
          filename = "monthly_works_#{user.actor.psu_id}_#{report_month}_#{today}.csv"
          expect(response.headers['Content-Type']).to eq 'text/csv'
          expect(response.headers['Content-Disposition']).to include filename
        end

        it 'returns the correct data in the CSV' do
          expect(response.status).to eq 200
          expect(csv.count).to eq 2
          expect(csv[1][0]).to eq work1.uuid
        end
      end
    end
  end
end
