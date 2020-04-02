# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Qa::TermsController, type: :controller, skip: ci_build? do
  before { @routes = Qa::Engine.routes }

  describe 'GET #search' do
    let(:search_results) { JSON.parse(response.body) }

    context 'when searching geonames' do
      before { get :search, params: { q: 'oslo', vocab: 'geonames' } }

      it 'returns a set of search results as JSON' do
        expect(search_results).to include('id' => 'http://sws.geonames.org/3143244/', 'label' => 'Oslo, Oslo, Norway')
      end
    end

    context 'when searching persons' do
      before { get :search, params: { q: 'daniel cough', vocab: 'persons' } }

      it 'returns a set of search results as JSON' do
        expect(search_results.first).to include('default_alias' => 'Daniel M Coughlin')
      end
    end
  end
end
