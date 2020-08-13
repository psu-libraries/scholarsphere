# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkDecorator do
  subject(:decorator) { described_class.new(work) }

  it 'extends ResourceDecorator' do
    expect(described_class).to be < ResourceDecorator
  end

  describe '#decorated_versions' do
    let(:work) { create :work, versions_count: 2, has_draft: true }

    it 'creates version decorators with their indices' do
      allow(WorkVersionDecorator).to receive(:new)
      decorator.decorated_versions
      expect(WorkVersionDecorator).to have_received(:new).with(work.versions[0])
      expect(WorkVersionDecorator).to have_received(:new).with(work.versions[1])
    end
  end

  describe '#decorated_latest_published_version' do
    let(:work) { instance_double 'Work', latest_published_version: latest_published_version }
    let(:latest_published_version) { instance_double 'WorkVersion' }

    it 'returns a decorated latest published version' do
      allow(WorkVersionDecorator).to receive(:new).with(latest_published_version).and_return(:decorated_version)

      expect(decorator.decorated_latest_published_version).to eq :decorated_version
    end
  end
end
