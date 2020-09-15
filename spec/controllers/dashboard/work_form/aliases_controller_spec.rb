# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::WorkForm::AliasesController, type: :controller do
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
            actor_id: actor.id
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
            default_alias: actor.default_alias
          }
        end

        its(:response) { is_expected.to be_successful }
      end
    end
  end

  context 'when the user is NOT logged in' do
    before { post :new }

    its(:response) { is_expected.to redirect_to new_user_session_path }
  end
end
