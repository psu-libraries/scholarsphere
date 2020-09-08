# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Errors routes', type: :routing do
  describe '#not_found' do
    specify do
      expect(get('/404')).to route_to(controller: 'errors', action: 'not_found')
    end

    specify do
      expect(get('/401')).to route_to(controller: 'errors', action: 'not_found')
    end
  end

  describe '#server_error' do
    specify do
      expect(get('/500')).to route_to(controller: 'errors', action: 'server_error')
    end
  end
end
