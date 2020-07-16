# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Pages Routes', type: :routing do
  describe '#home' do
    it 'routes to the home page' do
      expect(get('/')).to route_to(controller: 'pages', action: 'home')
    end
  end
end
