# frozen_string_literal: true

require 'rails_helper'

describe 'API V1 DOIs', type: :request do
  let!(:collection) { create :collection, doi: 'doi:10.26207/utaj-jfhi' }

  let(:api_token) { create(:api_token).token }
  let(:json_response) { JSON.parse(response.body) }

  let(:headers) { { 'X-API-Key' => api_token } }

  describe 'GET /api/v1/dois/*' do
    before do
      Collection.reindex_all
      get '/api/v1/dois/10.26207/utaj-jfhi', headers: headers
    end

    it 'returns a valid response' do
      expect(response).to be_ok
      expect(json_response).to match_array([{ 'url' => "/resources/#{collection.uuid}" }])
    end
  end
end
