# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::WorkDecorator do
  it 'extends SimpleDelegator' do
    expect(described_class).to be < SimpleDelegator
  end

  describe '#versions' do
    subject(:decorator) { described_class.new(work) }

    let(:work) { create :work, versions_count: 2, has_draft: true }

    it 'creates version decorators with their indices' do
      allow(Dashboard::WorkVersionDecorator).to receive(:new)
      decorator.versions
      expect(Dashboard::WorkVersionDecorator).to have_received(:new).with(work.versions[0])
      expect(Dashboard::WorkVersionDecorator).to have_received(:new).with(work.versions[1])
    end
  end
end
