# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::FileVersionMembershipsController, type: :controller do
  let(:user) { work_version.depositor.user }
  let(:work_version) { create :work_version, :draft, :with_files }
  let(:file_membership) { work_version.file_version_memberships.first }

  describe 'GET #edit' do
    let(:perform_request) { get :edit, params: { id: file_membership.to_param } }

    it_behaves_like 'an authorized dashboard controller'

    context 'when signed in' do
      before { sign_in user }

      context 'when requesting a file on a DRAFT version of my work' do
        it 'returns a success response' do
          perform_request
          expect(response).to be_successful
        end
      end

      context 'when requesting a file on a PUBLISHED version of my own work' do
        let(:work_version) { create :work_version, :published, :with_files }

        it 'returns not authorized' do
          expect {
            perform_request
          }.to raise_error(Pundit::NotAuthorizedError)
        end
      end
    end
  end

  describe 'PATCH #update' do
    let(:perform_request) do
      patch :update, params: {
        id: file_membership.to_param,
        file_version_membership: attributes
      }
    end

    let(:attributes) { valid_attributes }
    let(:valid_attributes) { { 'title' => 'Edited Filename.png' } }
    let(:invalid_attributes) { { 'title' => '' } }

    it_behaves_like 'an authorized dashboard controller'

    context 'when signed in' do
      before { sign_in user }

      context 'with valid params' do
        let(:attributes) { valid_attributes }

        before { perform_request }

        it { is_expected.to redirect_to dashboard_work_version_file_list_path(work_version) }
      end

      context 'with invalid params' do
        let(:attributes) { invalid_attributes }

        before { perform_request }

        it { is_expected.to render_template(:edit) }
      end

      context 'when requesting a file on a PUBLISHED version of my own work' do
        let(:work_version) { create :work_version, :published, :with_files }

        it 'returns not authorized' do
          expect {
            perform_request
          }.to raise_error(Pundit::NotAuthorizedError)
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:perform_request) { delete :destroy, params: { id: file_membership.to_param } }

    it_behaves_like 'an authorized dashboard controller'

    context 'when signed in' do
      before { sign_in user }

      context 'when requesting a file on a DRAFT version of my own work' do
        before { perform_request }

        it { is_expected.to redirect_to dashboard_work_version_file_list_path(work_version) }
      end

      context 'when requesting a file on a PUBLISHED version of my own work' do
        let(:work_version) { create :work_version, :published, :with_files }

        it 'returns not authorized' do
          expect {
            perform_request
          }.to raise_error(Pundit::NotAuthorizedError)
        end
      end
    end
  end
end
