# frozen_string_literal: true

require 'omniauth/strategies/oauth2'

module OmniAuth
  module Strategies
    class Psu < OmniAuth::Strategies::OAuth2
      option :name, :psu

      option :client_options,
             site: ENV['OAUTH_APP_URL'],
             authorize_path: '/oauth/authorize'

      uid do
        raw_info['uid']
      end

      info do
        raw_info
      end

      def raw_info
        @raw_info ||= access_token.get('/user.json').parsed
      end
    end
  end
end
