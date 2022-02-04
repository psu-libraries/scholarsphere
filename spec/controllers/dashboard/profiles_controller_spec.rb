# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::ProfilesController, type: :controller do
  let(:actor_attrs) { attributes_for(:actor) }

  let(:valid_attributes) {
    {
      'display_name' => "Dr. #{actor_attrs[:given_name]} #{actor_attrs[:surname]} PhD",
      'given_name' => actor_attrs[:given_name],
      'surname' => actor_attrs[:surname],
      'email' => actor_attrs[:email]
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

      it { is_expected.to redirect_to root_path }
    end
  end

  describe 'PUT #update' do
    context 'when signed in' do
      before { sign_in user }

      context 'with valid params' do
        it 'updates the profile' do
          put :update, params: { actor: valid_attributes }

          actor.reload
          expect(actor.display_name).to eq "Dr. #{actor_attrs[:given_name]} #{actor_attrs[:surname]} PhD"
          expect(actor.given_name).to eq actor_attrs[:given_name]
          expect(actor.surname).to eq actor_attrs[:surname]
          expect(actor.email).to eq actor_attrs[:email]
        end

        it "redirects to the user's dashboard" do
          put :update, params: { actor: valid_attributes }
          expect(response).to redirect_to(dashboard_root_path)
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

      it { is_expected.to redirect_to root_path }
    end
  end
end
