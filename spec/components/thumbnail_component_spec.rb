# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ThumbnailComponent, type: :component do
  let(:result) { render_inline(component) }

  context 'when featured is true' do
    let(:resource) { instance_spy('Resource', work_type: 'dataset') }
    let(:component) { described_class.new(resource: resource, featured: true) }

    it 'renders a thumbnail for a featured work' do
      expect(result.css('div').first.classes).to contain_exactly('col-xxl-6', 'ft-work__img', 'thumbnail-icon')
      expect(result.css('div').first.text).to include('analytics')
    end

    context 'when thumbnail_url is present' do
      it 'renders a thumbnail with image tag' do
        allow_any_instance_of(ThumbnailUrlService).to receive(:url).and_return 'url.com/path/file'
        expect(result.css('div').first.classes).to contain_exactly('col-xxl-6', 'ft-work__img', 'thumbnail-image')
        expect(result.css('img').attribute('src').value).to include('url.com/path/file')
      end
    end
  end

  context 'when featured is false' do
    let(:resource) { instance_spy('Resource', work_type: 'dataset') }
    let(:component) { described_class.new(resource: resource) }

    it 'renders a thumbnail for a featured work' do
      expect(result.css('div').first.classes).to contain_exactly('thumbnail-icon')
      expect(result.css('div').first.text).to include('analytics')
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

  context 'with an unexpected class' do
    let(:resource) { instance_spy('UnknownResource') }
    let(:component) { described_class.new(resource: resource) }

    it 'renders a default thumbnail' do
      expect(result.css('div').first.classes).to contain_exactly('thumbnail-icon')
      expect(result.css('div').first.text).to include('bar_chart')
    end
  end

  context 'when thumbnail_url is present' do
    let(:resource) { WorkVersion.new }
    let(:component) { described_class.new(resource: resource) }

    it 'renders a thumbnail with image tag' do
      allow_any_instance_of(ThumbnailUrlService).to receive(:url).and_return 'url.com/path/file'
      expect(result.css('div').first.classes).to contain_exactly('thumbnail-image')
      expect(result.css('img').attribute('src').value).to include('url.com/path/file')
    end
  end
end
