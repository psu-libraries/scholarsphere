# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::DoisController, type: :controller do
  let(:api_token) { create(:api_token).token }
  let(:json_response) { JSON.parse(response.body) }

  before { request.headers[:'X-API-Key'] = api_token }

  describe 'GET #index' do
    let(:mock_results) do
      {
        'doi:10.123/doi1' => ['uuid-1', 'uuid-2'],
        'doi:10.123/doi2' => ['uuid-3']
      }
    end

    before do
      allow(DoiSearch).to receive(:all).and_return mock_results
      get :index
    end

    it 'returns 200 and a json array of all DOIs' do
      expect(response).to be_ok
      expect(json_response).to match(
        {
          'doi:10.123/doi1' => ['uuid-1', 'uuid-2'],
          'doi:10.123/doi2' => ['uuid-3']
        }
      )
    end

    context 'when not authorized' do
      let(:api_token) { nil }
      let(:mock_search_results) { [] }

      specify { expect(response).to be_unauthorized }
    end
  end

  describe 'GET #show' do
    let(:mock_search) { instance_spy 'DoiSearch', results: mock_search_results }

    before do
      allow(DoiSearch).to receive(:new).and_return(mock_search)
      get :show, params: { doi: 'some-doi' }
    end

    context 'when a matching doi can be found' do
      let(:mock_search_results) { ['uuid-1', 'uuid-2'] }

      it 'returns 200 and a list of resource urls' do
        expect(DoiSearch).to have_received(:new).with(doi: 'some-doi')
        expect(response).to be_ok
        expect(json_response).to contain_exactly({ 'url' => '/resources/uuid-1' }, { 'url' => '/resources/uuid-2' })
      end
    end

    context 'when no matching doi can be found' do
      let(:mock_search_results) { [] }

      it 'returns 404' do
        expect(response).to be_not_found
        expect(response.body).to be_blank
      end
    end

    context 'when not authorized' do
      let(:api_token) { nil }
      let(:mock_search_results) { [] }

      specify { expect(response).to be_unauthorized }
    end
  end
end
