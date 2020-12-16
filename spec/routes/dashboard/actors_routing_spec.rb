# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::Form::ActorsController, type: :routing do
  describe 'routing' do
    it 'routes to #new' do
      expect(get: '/dashboard/form/work_versions/1/actors/new').to route_to(
        { controller: 'dashboard/form/actors', action: 'new', resource_klass: 'work_versions', id: '1' }
      )
    end

    it 'routes to #create' do
      expect(post: '/dashboard/form/work_versions/1/actors/new').to route_to(
        { controller: 'dashboard/form/actors', action: 'create', resource_klass: 'work_versions', id: '1' }
      )
    end
  end
end
