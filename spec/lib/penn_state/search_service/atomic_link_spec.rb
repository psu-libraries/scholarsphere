# frozen_string_literal: true

require 'spec_helper'
require 'penn_state/search_service'

RSpec.describe PennState::SearchService::AtomicLink do
  it { is_expected.to be_a(OpenStruct) }

  context 'when the link is nil' do
    subject { described_class.new }

    its(:href) { is_expected.to be_nil }
    its(:rel) { is_expected.to be_nil }
    its(:title) { is_expected.to be_nil }
    its(:type) { is_expected.to be_nil }
  end

  context 'when a link is present' do
    subject(:link) do
      described_class.new(
        'href' => 'http://something.com',
        'rel' => 'relative',
        'title' => 'Link Title',
        'type' => 'link type'
      )
    end

    its(:href) { is_expected.to eq('http://something.com') }
    its(:rel) { is_expected.to eq('relative') }
    its(:title) { is_expected.to eq('Link Title') }
    its(:type) { is_expected.to eq('link type') }

    it 'displays the link' do
      expect(link.to_s).to eq('http://something.com')
    end
  end
end
