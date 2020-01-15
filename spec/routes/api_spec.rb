# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API Routes', type: :routing do
  describe 'v1' do
    it 'routes to the ingest controller' do
      expect(post('/api/v1/ingest')).to route_to(controller: 'api/v1/ingest', action: 'create')
    end
  end
end
