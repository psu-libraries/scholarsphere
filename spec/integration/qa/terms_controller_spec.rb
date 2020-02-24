# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Qa::TermsController, type: :controller, skip: ci_build? do
  before { @routes = Qa::Engine.routes }

  context 'when searching geonames' do
    let(:search_results) { JSON.parse(response.body) }

    before { get :search, params: { q: 'oslo', vocab: 'geonames' } }

    it 'returns a set of search results as JSON' do
      expect(search_results).to include('id' => 'http://sws.geonames.org/3143244/', 'label' => 'Oslo, Oslo, Norway')
    end
  end
end
