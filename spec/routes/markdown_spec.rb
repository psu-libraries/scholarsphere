# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Markdown Routes', type: :routing do
  describe '#about' do
    it 'routes to the about page' do
      expect(get('/about')).to route_to(controller: 'markdown', action: 'show', page: 'about')
    end
  end
end
