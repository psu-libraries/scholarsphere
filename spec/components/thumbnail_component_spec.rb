# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ThumbnailComponent, type: :component do
  let(:result) { render_inline(component) }
  let(:resource) { instance_spy('Resource') }

  context 'when featured is true' do
    let(:component) { described_class.new(resource: resource, featured: true) }

    it 'renders a thumbnail for a featured work' do
      expect(result.css('div').first.classes).to contain_exactly('col-xxl-6', 'ft-work__img', 'thumbnail')
      expect(result.css('div').first.text).to include('bar_chart')
    end
  end

  context 'when featured is false' do
    let(:component) { described_class.new(resource: resource) }

    it 'renders a thumbnail for a featured work' do
      expect(result.css('div').first.classes).to contain_exactly('thumbnail')
      expect(result.css('div').first.text).to include('bar_chart')
    end
  end
end
