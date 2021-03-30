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
        it 'does nothing' do
          expect {
            post :update, params: { id: work.id, work: { visibility: 'bogus' } }
          }.not_to change(work, :visibility)
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
end
