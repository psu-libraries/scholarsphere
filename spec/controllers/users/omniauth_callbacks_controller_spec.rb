# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  let(:oauth_response) { build :psu_oauth_response }
  let(:user) { build_stubbed :user }

  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:psu] = oauth_response

    request.env['devise.mapping'] = Devise.mappings[:user]
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:psu]

    allow(User).to receive(:from_omniauth)
      .with(oauth_response)
      .and_return(user)
  end

  describe '#psu' do
    context 'when the user persists correctly' do
      before do
        allow(user).to receive(:persisted?).and_return(true)
        get :psu
      end

      it 'signs in the user' do
        expect(warden.authenticated?(:user)).to eq true
      end

      it 'sets current_user' do
        expect(controller.current_user).to eq user
      end
    end

    context 'when the user does not persist' do
      before do
        allow(user).to receive(:persisted?).and_return(false)
        get :psu
      end

      it 'saves the oauth response to a session variable' do
        expect(session['devise.doorkeeper_data']).to eq oauth_response
      end

      it { is_expected.to redirect_to root_path }
    end
  end
end
