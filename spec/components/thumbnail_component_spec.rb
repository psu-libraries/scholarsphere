# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ThumbnailComponent, type: :component do
  let(:result) { render_inline(component) }

  context 'when featured is true' do
    let(:resource) { instance_spy('Resource', work_type: 'dataset') }
    let(:component) { described_class.new(resource: resource, featured: true) }

    context 'when default thumbnail' do
      it 'renders a thumbnail for a featured work' do
        allow(resource).to receive(:default_thumbnail?).and_return true
        expect(result.css('div').first.classes).to contain_exactly('ft-work__img', 'thumbnail-icon')
        expect(result.css('div').first.text).to include('analytics')
      end
    end

    context 'when uploaded thumbnail' do
      it 'renders a thumbnail with image tag' do
        allow(resource).to receive(:auto_generated_thumbnail?).and_return false
        allow(resource).to receive(:default_thumbnail?).and_return false
        allow(resource).to receive(:thumbnail_url).and_return 'url.com/path/file'
        expect(result.css('div').first.classes).to contain_exactly('ft-work__img',
                                                                   'thumbnail-image')
        expect(result.css('img').attribute('src').value).to include('url.com/path/file')
      end
    end
  end

  context 'when featured is false' do
    let(:resource) { instance_spy('Resource', work_type: 'dataset') }
    let(:component) { described_class.new(resource: resource) }

    context 'when default thumbnail' do
      it 'renders a thumbnail' do
        allow(resource).to receive(:default_thumbnail?).and_return true
        allow(resource).to receive(:auto_generated_thumbnail?).and_return false
        expect(result.css('div').first.classes).to contain_exactly('thumbnail-icon')
      end
    end

    context 'when uploaded thumbnail' do
      it 'renders a thumbnail with image tag' do
        allow(resource).to receive(:auto_generated_thumbnail?).and_return false
        allow(resource).to receive(:default_thumbnail?).and_return false
        allow(resource).to receive(:thumbnail_url).and_return 'url.com/path/file'
        expect(result.css('div').first.classes).to contain_exactly('thumbnail-image')
        expect(result.css('img').attribute('src').value).to include('url.com/path/file')
      end
    end
  end

  context 'with a collection' do
    let(:resource) { Collection.new }
    let(:component) { described_class.new(resource: resource) }

    it 'renders a thumbnail' do
      expect(result.css('div').first.classes).to contain_exactly('thumbnail-icon')
      expect(result.css('div').first.text).to include('view_carousel')
    end
  end

  context 'with a collection decorator' do
    let(:resource) { CollectionDecorator.new(Collection.new) }
    let(:component) { described_class.new(resource: resource) }

    it 'renders a thumbnail' do
      expect(result.css('div').first.classes).to contain_exactly('thumbnail-icon')
      expect(result.css('div').first.text).to include('view_carousel')
    end
  end
end
