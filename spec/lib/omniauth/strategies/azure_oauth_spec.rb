# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OmniAuth::Strategies::AzureOauth do
  include Rack::Test::Methods

  let(:app) do
    Rack::Builder.new do |b|
      b.use Rack::Session::Cookie, secret: 'abc123'
      b.use OmniAuth::Strategies::AzureOauth
      b.run lambda { |_env| [200, {}, ['Not Found']] }
    end.to_app
  end

  let(:client) do
    OAuth2::Client.new(
      ENV.fetch('OAUTH_APP_ID', nil),
      ENV.fetch('OAUTH_APP_SECRET', nil),
      authorize_url: ENV.fetch('OAUTH_AUTHORIZE_URL', nil),
      token_url: ENV.fetch('OAUTH_TOKEN_URL', nil),
      site: ENV.fetch('OAUTH_APP_URL', nil)
    )
  end

  let(:strategy) { described_class.new(app) }
  let(:access_token) { { 'id_token' => "prefix.#{Base64.encode64(auth_hash.to_json)}" } }
  let(:auth_hash) { build(:psu_oauth_response) }

  before { strategy.access_token = OAuth2::AccessToken.from_hash(client, access_token) }

  describe 'POST /users/auth/azure_oauth' do
    subject { last_response }

    before { post '/users/auth/azure_oauth' }

    its(:status) { is_expected.to eq(302) }
  end

  describe '.uid' do
    subject { strategy.uid }

    it { is_expected.to eq(auth_hash.uid) }
  end

  describe '.info', :vcr do
    subject(:info) { strategy.info }

    # @note If you want to re-create the VCR file. You will need to save an existing access token as a json file from a
    # session created in development mode:
    #
    #   File.write('tmp/access_token.json', access_token.to_hash.to_json)
    #
    # Then load the token during the test:
    #
    #   let(:access_token) { JSON.parse(File.read('tmp/access_token.json')) }
    #
    # After the responses are recorded, remove the record: :all directive and modify the yaml files to remove the bearer
    # tokens.
    context 'with an unpaginated response' do
      before { ENV['AZURE_GRAPH_GROUPS'] = 'true' }

      specify do
        expect(info['groups'].count).to eq(42)
      end
    end

    # @note When re-creating the response, make the same changes above, and in addition record each request by changing
    # the VCR configuration:
    #
    #   vcr: { record: :all }
    #
    # Change the graph url to https://graph.microsoft.com/v1.0/me/memberOf?$top=20 or another such number to force
    # pagination of the user's groups. After the responses are recorded, remove tokens and change the initial uri *back*
    # to the origin graph url.
    context 'with a paginated response' do
      before { ENV['AZURE_GRAPH_GROUPS'] = 'true' }

      specify do
        expect(info['groups'].count).to eq(42)
      end
    end

    context 'when AZURE_GRAPH_GROUPS is not present' do
      before { ENV['AZURE_GRAPH_GROUPS'] = nil }

      specify do
        expect(info['groups']).to be_empty
      end
    end

    context 'when previous groups exist' do
      let(:auth_hash) { build(:psu_oauth_response, main_groups: groups) }
      let(:groups) { Array.new(3) { "umg-.#{Faker::Currency.code.downcase}" } }

      before { ENV['AZURE_GRAPH_GROUPS'] = nil }

      specify do
        expect(info['groups']).to eq(groups)
      end
    end
  end
end
