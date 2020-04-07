# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::ProfilesController, type: :controller do
  let(:valid_attributes) {
    {
      'default_alias' => 'Dr. Pat Q. Researcher PhD',
      'given_name' => 'Pat',
      'surname' => 'Researcher',
      'email' => 'pqr123@example.com',
      'orcid' => '0000-1234-5678-9101'
    }
  }

  let(:invalid_attributes) {
    {
      'surname' => ''
    }
  }

  let(:user) { create :user }
  let(:actor) { user.actor }

  describe 'GET #edit' do
    context 'when signed in' do
      before { log_in user }

      it 'returns a success response' do
        get :edit
        expect(response).to be_successful
      end

      it 'shows my profile' do
        get :edit
        expect(assigns(:actor).id).to eq actor.id
      end
    end

    context 'when not signed in' do
      subject { response }

      before { get :edit }

      it { is_expected.to redirect_to new_user_session_path }
    end
  end

  describe 'PUT #update' do
    context 'when signed in' do
      before { sign_in user }

      context 'with valid params' do
        it 'updates the profile' do
          put :update, params: { actor: valid_attributes }

          actor.reload
          expect(actor.default_alias).to eq 'Dr. Pat Q. Researcher PhD'
          expect(actor.given_name).to eq 'Pat'
          expect(actor.surname).to eq 'Researcher'
          expect(actor.email).to eq 'pqr123@example.com'
          expect(actor.orcid).to eq '0000-1234-5678-9101'
        end

        it 'redirects to the dashboard works page' do
          put :update, params: { actor: valid_attributes }
          expect(response).to redirect_to(dashboard_works_path) # WIP
        end
      end

      context 'with invalid params' do
        it "returns a success response (i.e. to display the 'edit' template)" do
          put :update, params: { actor: invalid_attributes }
          expect(response).to be_successful
        end
      end
    end

    context 'when not signed in' do
      subject { response }

      before { put :update, params: { work: valid_attributes } }

      it { is_expected.to redirect_to new_user_session_path }
    end
  end
end
