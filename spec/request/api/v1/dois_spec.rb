# frozen_string_literal: true

require 'rails_helper'

describe 'API V1 DOIs', type: :request do
  let!(:collection) { create :collection, doi: 'doi:10.26207/utaj-jfhi' }

  let(:api_token) { create(:api_token).token }
  let(:json_response) { JSON.parse(response.body) }

  let(:headers) { { 'X-API-Key' => api_token } }

  before { Collection.reindex_all }

  describe 'GET /api/v1/dois' do
    before { get '/api/v1/dois', headers: headers }

    it 'returns a valid response' do
      expect(response).to be_ok
      expect(json_response).to match({ 'doi:10.26207/utaj-jfhi' => [collection.uuid] })
    end
  end

  describe 'GET /api/v1/dois/*' do
    before { get '/api/v1/dois/10.26207/utaj-jfhi', headers: headers }

    it 'returns a valid response' do
      expect(response).to be_ok
      expect(json_response).to match_array([{ 'url' => "/resources/#{collection.uuid}" }])
    end
  end
end
