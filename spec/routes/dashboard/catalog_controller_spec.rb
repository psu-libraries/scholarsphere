# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::CatalogController, type: :routing do
  describe '/dashboard/catalog' do
    subject { get('/dashboard/catalog') }

    it { is_expected.to route_to(controller: 'dashboard/catalog', action: 'index') }
  end

  describe '/dashboard' do
    subject { get('/dashboard') }

    it { is_expected.to route_to(controller: 'dashboard/catalog', action: 'index') }
  end
end
