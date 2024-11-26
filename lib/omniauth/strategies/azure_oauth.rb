# frozen_string_literal: true

require 'omniauth/strategies/oauth2'

module OmniAuth
  module Strategies
    class AzureOauth < OmniAuth::Strategies::OAuth2
      GRAPH_URL = 'https://graph.microsoft.com/v1.0/me/memberOf'

      option :name, :azure_oauth

      option :authorize_params,
             domain_hint: ENV.fetch('AZURE_DOMAIN_HINT', 'psu.edu')

      option :client_options,
             site: ENV['OAUTH_APP_URL'],
             token_url: ENV.fetch('OAUTH_TOKEN_URL', '/oauth/token'),
             authorize_url: ENV.fetch('OAUTH_AUTHORIZE_URL', 'oauth/authorize')

      uid do
        raw_info['upn'].split('@')[0]
      end

      # @note Groups may be populated with data prior to this point. If AZURE_GRAPH_GROUPS is present, we will overwrite
      # that data with the data returned from the group query. If AZURE_GRAPH_GROUPS is not present, then we leave the
      # group data alone, but ensure that there isn't any nil value.
      info do
        raw_info['groups'] ||= []
        raw_info['groups'] = graph_groups if ENV['AZURE_GRAPH_GROUPS'].present?
        raw_info
      end

      # @note Override callback URL. OmniAuth by default passes the entire URL of the callback, including query
      # parameters. Azure fails validation because that doesn't match the registered callback.
      def callback_url
        options[:redirect_uri] || (full_host + script_name + callback_path)
      end

      def raw_info
        @raw_info ||= JSON.parse(Base64.decode64(access_token['id_token'].split('.')[1]))
      end

      private

        def graph_groups
          @graph_groups ||= group_query(url: GRAPH_URL)
        end

        def group_query(url:, groups: [])
          return groups if url.nil?

          resp = access_token.get(url).parsed
          groups += resp.fetch('value', []).map { |x| x['onPremisesSamAccountName'] || x['displayName'] }
          group_query(url: resp['@odata.nextLink'], groups: groups)
        end
    end
  end
end
