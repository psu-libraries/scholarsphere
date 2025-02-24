# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::PublicController do
  let(:json_response) { ActiveSupport::HashWithIndifferentAccess.new(response.parsed_body) }

  describe 'POST #execute' do
    context 'without any parameters' do
      before { post :execute }

      its(:status) { is_expected.to eq 200 }

      it 'returns an error message' do
        expect(json_response[:errors]).to include(message: 'No query string was present')
      end
    end

    context 'when querying a work' do
      let(:resource) { create(:work) }
      let(:query) do
        <<-QUERY
          {
            work(id: "#{resource.uuid}") {
              title
              description
            }
          }
        QUERY
      end

      before { post :execute, params: { query: query } }

      its(:status) { is_expected.to eq 200 }

      it 'returns the title and description' do
        expect(json_response.dig('data', 'work', 'title')).to eq(resource.versions[0].title)
        expect(json_response.dig('data', 'work', 'description')).to eq(resource.versions[0].description)
      end
    end

    context 'when querying for authenticated-only content' do
      let!(:api_key) { create(:api_token) }
      let(:resource) { create(:work, :with_authorized_access, has_draft: false) }
      let(:query) do
        <<-QUERY
          {
            work(id: "#{resource.uuid}") {
              files {
                filename
              }
            }
          }
        QUERY
      end

      before do
        request.headers[:'X-API-Key'] = api_key.token
        post :execute, params: { query: query }
      end

      it 'returns a list of files' do
        expect(json_response.dig('data', 'work', 'files')).not_to be_empty
      end
    end

    context 'when using variables' do
      let(:resource) { create(:work) }
      let(:query) do
        <<-QUERY
          query FindResource($id: ID!) {
            work(id: $id) {
              title
              description
            }
          }
        QUERY
      end

      let(:variables) do
        <<-VARIABLES
          {
            "id": "#{resource.uuid}"
          }
        VARIABLES
      end

      before { post :execute, params: { query: query, variables: variables } }

      its(:status) { is_expected.to eq 200 }

      it 'returns the title and description' do
        expect(json_response.dig('data', 'work', 'title')).to eq(resource.versions[0].title)
        expect(json_response.dig('data', 'work', 'description')).to eq(resource.versions[0].description)
      end
    end

    context 'with malformed JSON variables' do
      before { post :execute, params: { query: '{}', variables: 'this is not json' } }

      its(:status) { is_expected.to eq 200 }
    end
  end
end
