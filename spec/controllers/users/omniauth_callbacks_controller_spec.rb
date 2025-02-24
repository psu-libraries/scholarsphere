# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController do
  let(:oauth_response) { build(:psu_oauth_response) }
  let(:user) { build_stubbed(:user) }

  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:azure_oauth] = oauth_response

    request.env['devise.mapping'] = Devise.mappings[:user]
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:azure_oauth]

    allow(User).to receive(:from_omniauth)
      .with(oauth_response)
      .and_return(user)
  end

  describe '#azure_oauth' do
    context 'when the user persists correctly' do
      context 'when the login is not initiated from a storable location' do
        before do
          get :azure_oauth
        end

        it 'signs in the user' do
          expect(warden.authenticated?(:user)).to eq true
        end

        it 'sets current_user' do
          expect(controller.current_user).to eq user
        end

        it { is_expected.to redirect_to root_path }
      end

      context 'when the login is initiated from a storable location' do
        before do
          controller.store_location_for(:user, about_path)
          get :azure_oauth
        end

        it 'signs in the user' do
          expect(warden.authenticated?(:user)).to eq true
        end

        it 'sets current_user' do
          expect(controller.current_user).to eq user
        end

        it { is_expected.to redirect_to about_path }
      end
    end

    context 'when the user does not persist' do
      before do
        allow(User).to receive(:from_omniauth)
          .with(oauth_response)
          .and_raise(User::OAuthError)
        get :azure_oauth
      end

      it { is_expected.to redirect_to root_path }
    end
  end
end
