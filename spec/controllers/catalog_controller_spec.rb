# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CatalogController do
  describe 'GET #search' do
    it 'does NOT save search history' do
      expect {
        get :index, params: { q: 'foo' }
      }.not_to change(Search, :count)
    end
  end
end
