# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::ActorsController, type: :routing do
  describe 'routing' do
    it 'routes to #new' do
      expect(get: '/dashboard/actors/new').to route_to('dashboard/actors#new')
    end

    it 'routes to #create' do
      expect(post: '/dashboard/actors').to route_to('dashboard/actors#create')
    end
  end
end
