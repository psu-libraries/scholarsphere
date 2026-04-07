# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'BotChallengePage' do
  subject(:allow_exempt) { BotChallengePage::BotChallengePageController.bot_challenge_config.allow_exempt }

  let(:request) { instance_double(ActionDispatch::Request, headers: { 'User-Agent' => user_agent }) }
  let(:controller) { instance_double(ApplicationController, current_user: current_user, request: request) }

  context 'when user is authenticated' do
    let(:current_user) { create(:user) }
    let(:user_agent) { 'Mozilla/5.0' }

    it 'exempts the request from challenge' do
      expect(allow_exempt.call(controller, nil)).to be true
    end
  end

  context 'when user is a guest' do
    let(:current_user) { User.guest }

    context 'when user agent is not a bot' do
      let(:user_agent) { 'Mozilla/5.0' }

      it 'does not exempt the request' do
        expect(allow_exempt.call(controller, nil)).to be false
      end
    end

    context 'when user agent is a bot' do
      let(:user_agent) { 'Googlebot' }

      it 'exempts the request' do
        expect(allow_exempt.call(controller, nil)).to be true
      end
    end
  end
end
