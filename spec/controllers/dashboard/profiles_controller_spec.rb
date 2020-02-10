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
      'email' => ''
    }
  }

  let(:user) { create :user }
  let(:creator) { Creator.find_or_create_by_user(user) }

  describe 'GET #edit' do
    context 'when signed in' do
      before { log_in user }

      it 'returns a success response' do
        get :edit
        expect(response).to be_successful
      end

      it 'shows my profile' do
        get :edit
        expect(assigns(:creator).id).to eq creator.id
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
          put :update, params: { creator: valid_attributes }

          creator.reload
          expect(creator.default_alias).to eq 'Dr. Pat Q. Researcher PhD'
          expect(creator.given_name).to eq 'Pat'
          expect(creator.surname).to eq 'Researcher'
          expect(creator.email).to eq 'pqr123@example.com'
          expect(creator.orcid).to eq '0000-1234-5678-9101'
        end

        it 'redirects to the dashboard works page' do
          put :update, params: { creator: valid_attributes }
          expect(response).to redirect_to(dashboard_works_path) # WIP
        end
      end

      context 'with invalid params' do
        it "returns a success response (i.e. to display the 'edit' template)" do
          put :update, params: { creator: invalid_attributes }
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
