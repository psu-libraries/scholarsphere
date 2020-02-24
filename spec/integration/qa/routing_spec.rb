# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Qa::Engine, type: :routing do
  context 'when searching a given authority' do
    specify do
      expect(get: '/authorities/search/vocabulary')
        .to route_to(controller: 'qa/terms', action: 'search', vocab: 'vocabulary')
    end
  end

  context 'when returning all the terms in an authority' do
    specify do
      expect(get: '/authorities/terms/vocabulary')
        .to route_to(controller: 'qa/terms', action: 'index', vocab: 'vocabulary')
    end
  end

  context 'when reuturning a single authority term' do
    specify do
      expect(get: '/authorities/show/vocabulary/1')
        .to route_to(controller: 'qa/terms', action: 'show', vocab: 'vocabulary', id: '1')
    end
  end

  context 'with a subauthority' do
    specify do
      expect(get: '/authorities/terms/vocabulary/subauthority')
        .to route_to(controller: 'qa/terms', action: 'index', vocab: 'vocabulary', subauthority: 'subauthority')
    end
  end
end
