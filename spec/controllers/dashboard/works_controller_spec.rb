# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::WorksController, type: :controller do
  let(:valid_attributes) {
    {
      'work' => {
        'visibility' => Permissions::Visibility.default
      }
    }
  }

  let(:invalid_attributes) {
    {
      'embargo_form' => {
        'embargoed_until' => 'not a valid date'
      }
    }
  }

  let(:work) { create :work, depositor: user.actor }

  let(:user) { create :user }

  describe 'GET #edit' do
    context 'when signed in' do
      before do
        log_in user
        get :edit, params: { id: work.id }
      end

      it 'returns a success response' do
        expect(response).to be_successful
      end
    end

    context 'when not signed in' do
      subject { response }

      before { get :edit, params: { id: work.id } }

      it { is_expected.to redirect_to root_path }
    end
  end

  describe 'POST #update' do
    let(:perform_request) {
      post :update, params: { id: work.id }.merge(attributes)
    }

    context 'when signed in' do
      before { sign_in user }

      context 'with valid params' do
        let(:attributes) { valid_attributes }

        before { perform_request }

        it 'redirects to the updated work settings page' do
          expect(response).to redirect_to(edit_dashboard_work_path(work))
        end
      end

      context 'with invalid params' do
        let(:attributes) { invalid_attributes }

        it 're-renders the form' do
          perform_request
          expect(response).to render_template(:edit)
        end
      end

      context 'with an invalid visibility' do
        it 'raises an error' do
          expect { post :update, params: { id: work.id, work: { visibility: 'bogus' } } }.to raise_error(ArgumentError)
        end
      end
    end

    context 'when not signed in' do
      subject { response }

      let(:attributes) { valid_attributes }

      before { perform_request }

      it { is_expected.to redirect_to root_path }
    end
  end

  describe 'DELETE #destroy' do
    let(:users_work) { create :work, depositor: user.actor }
    let(:someone_elses_work) { create :work }

    context 'when signed in' do
      before { sign_in user }

      context 'when the user owns the work' do
        let!(:work) { users_work }

        it 'destroys the requested work' do
          expect {
            delete :destroy, params: { id: work.to_param }
          }.to change(Work, :count).by(-1)
        end

        it 'redirects to the works list' do
          delete :destroy, params: { id: work.to_param }
          expect(response).to redirect_to(dashboard_root_path)
        end
      end

      context 'when the user does not own the work' do
        let!(:work) { someone_elses_work }

        it '404s' do
          expect {
            delete :destroy, params: { id: work.to_param }
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'when not signed in' do
      subject { response }

      let!(:work) { users_work }

      before { delete :destroy, params: { id: work.to_param } }

      it { is_expected.to redirect_to root_path }
    end
  end
end
