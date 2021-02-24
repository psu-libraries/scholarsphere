# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::Form::AuthorshipsController, type: :controller do
  describe 'POST #new' do
    context 'when the user is logged in' do
      let(:user) { create(:user) }
      let(:actor) { create(:actor) }

      render_views

      before do
        log_in user
        post :new, params: params
      end

      context 'when the actor id is present' do
        let(:params) do
          {
            actor_id: actor.id,
            resource_klass: 'work_version',
            id: '1'
          }
        end

        its(:response) { is_expected.to be_successful }
      end

      context 'when the actor id is NOT present' do
        let(:params) do
          {
            given_name: actor.given_name,
            surname: actor.surname,
            psu_id: actor.psu_id,
            email: actor.email,
            orcid: actor.orcid,
            display_name: actor.display_name,
            resource_klass: 'work_version',
            id: '1'
          }
        end

        its(:response) { is_expected.to be_successful }
      end
    end
  end

  context 'when the user is NOT logged in' do
    before { post :new, params: { resource_klass: 'work_version', id: '1' } }

    its(:response) { is_expected.to redirect_to new_user_session_path }
  end
end
