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
      ENV['OAUTH_APP_ID'],
      ENV['OAUTH_APP_SECRET'],
      authorize_url: ENV['OAUTH_AUTHORIZE_URL'],
      token_url: ENV['OAUTH_TOKEN_URL'],
      site: ENV['OAUTH_APP_URL']
    )
  end

  let(:strategy) { described_class.new(app) }
  let(:access_token) { { 'id_token' => "prefix.#{Base64.encode64(auth_hash.to_json)}" } }
  let(:auth_hash) { build(:psu_oauth_response) }

  before { strategy.access_token = OAuth2::AccessToken.from_hash(client, access_token) }

  describe 'GET /users/auth/azure_oauth' do
    subject { last_response }

    before { get '/users/auth/azure_oauth' }

    its(:status) { is_expected.to eq(302) }
  end

  describe '.uid' do
    subject { strategy.uid }

    it { is_expected.to eq(auth_hash.uid) }
  end

  describe '.info' do
    subject { strategy.info }

    it { is_expected.to eq(auth_hash) }
  end

  describe '#graph_groups', :vcr do
    subject { strategy.graph_groups }

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
      its(:count) { is_expected.to eq(42) }
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
      its(:count) { is_expected.to eq(42) }
    end
  end
end
