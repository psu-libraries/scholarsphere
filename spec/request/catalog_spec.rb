# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CatalogController, type: :request do
  describe 'GET #index' do
    # @note Atom and RSS feeds are supported by default in Blacklight, but we're removing it on purpose because the view
    # partials provided in the gem are raising errors. Reinstating this feature would involve overriding the partials
    # to display correctly, but that is currently out of scope.
    context 'when requesting an rss feed' do
      specify do
        get '/catalog.rss'
        expect(response).to have_http_status(:not_acceptable)
      end
    end

    context 'when requesting an atom feed' do
      specify do
        get '/catalog.atom'
        expect(response).to have_http_status(:not_acceptable)
      end
    end
  end
end
