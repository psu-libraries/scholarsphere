# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::Form::ActorsController, type: :controller do
  let(:actor) { build(:actor) }

  let(:url_parameters) do
    {
      resource_klass: 'work_version',
      id: '1'
    }
  end

  let(:valid_attributes) do
    {
      surname: actor.surname,
      orcid: actor.orcid,
      given_name: actor.given_name,
      email: actor.email
    }
  end

  let(:invalid_attributes) do
    {
      surname: nil
    }
  end

  let(:user) { create(:user) }
  let(:admin) { create(:user, :admin) }

  describe 'GET /new' do
    context 'when signed in' do
      before do
        log_in user
        get :new, params: url_parameters
      end

      its(:response) { is_expected.to be_successful }
      specify { expect(assigns(:actor)).not_to be_nil }
    end

    context 'when not signed in' do
      before { get :new, params: url_parameters }

      its(:response) { is_expected.to redirect_to new_user_session_path }
    end
  end

  describe 'POST /create' do
    context 'when signed in' do
      before { log_in user }

      context 'with valid parameters' do
        it 'creates a new Actor' do
          expect {
            post :create, params: { actor: valid_attributes }.merge(url_parameters)
          }.to change(Actor, :count).by(1)
        end

        it 'returns json for the created actor' do
          post :create, params: { actor: valid_attributes }.merge(url_parameters)
          expect(response).to be_successful
          expect(response.body).to eq({ actor_id: Actor.last.id }.to_json)
        end
      end

      context 'with invalid parameters' do
        it 'does not create a new Actor' do
          expect {
            post :create, params: { actor: invalid_attributes }.merge(url_parameters)
          }.to change(Actor, :count).by(0)
        end

        it 'returns an unprocessable entity response' do
          post :create, params: { actor: invalid_attributes }.merge(url_parameters)
          expect(response).to be_unprocessable
        end
      end
    end

    context 'when not signed in' do
      before { post :create, params: { actor: valid_attributes }.merge(url_parameters) }

      its(:response) { is_expected.to redirect_to new_user_session_path }
    end
  end
end
