# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::FileListsController, type: :controller do
  let(:user) { work_version.depositor.user }
  let(:work_version) { create :work_version, :draft }

  describe 'GET #edit' do
    let(:perform_request) { get :edit, params: { work_version_id: work_version.to_param } }

    it_behaves_like 'an authorized dashboard controller'

    context 'when signed in' do
      let(:work_version) { create :work_version }

      before { sign_in user }

      context 'when requesting a DRAFT version of my own work' do
        it 'returns a success response' do
          perform_request
          expect(response).to be_successful
        end
      end

      context 'when requesting a PUBLISHED version of my own work' do
        let(:work_version) { create :work_version, :published }

        it 'returns not authorized' do
          expect {
            perform_request
          }.to raise_error(Pundit::NotAuthorizedError)
        end
      end
    end
  end

  # @note It's too hard to recreate valid shrine + uppy + s3 params here. We
  #       will test the happy path in a feature test.
  describe 'PATCH #update' do
    let(:perform_request) do
      patch :update, params: {
        work_version_id: work_version.to_param,
        work_version: invalid_attributes
      }
    end

    let(:invalid_attributes) {
      {
        'file_resources_attributes' => [
          'file' => { 'id' => 'bogus.jpg' }
        ]
      }
    }

    it_behaves_like 'an authorized dashboard controller'

    context 'when signed in' do
      before { sign_in user }

      context 'with invalid attributes' do
        let(:attributes) { invalid_attributes }

        before { perform_request }

        it { is_expected.to render_template :edit }
      end
    end
  end
end
