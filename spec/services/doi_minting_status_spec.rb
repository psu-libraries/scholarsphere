# frozen_string_literal: true

require 'rails_helper'

describe DoiMintingStatus do
  subject(:status) { described_class.new(resource) }

  let(:resource) { build_stubbed(:work) }

  describe '::STATUSES' do
    subject { described_class::STATUSES }

    it { is_expected.to match_array(%i(waiting minting error)) }
  end

  describe 'status-based methods' do
    described_class::STATUSES.each do |status|
      it { is_expected.to respond_to("#{status}!") }
      it { is_expected.to respond_to("#{status}?") }
    end
  end

  # All of these status-based predicate methods are metaprogrammed,
  # so I'm only going to test one
  describe '#waiting?' do
    subject { status.waiting? }

    context 'when the current status is not "waiting"' do
      before { status.delete! }

      it { is_expected.to eq false }
    end

    context 'when the current status is "waiting"' do
      before { status.waiting! }

      it { is_expected.to eq true }
    end
  end

  describe '#waiting!' do
    before { status.delete! }

    it 'sets the current status to waiting' do
      expect(status).not_to be_waiting # Sanity
      status.waiting!
      expect(status).to be_waiting
    end
  end

  describe '#delete!' do
    before { status.waiting! }

    it 'deletes the key from redis' do
      expect(status).to be_waiting # Sanity
      status.delete!
      expect(status).not_to be_present
    end
  end

  describe '#present?' do
    subject { status.present? }

    context 'when the key is present in redis' do
      before { status.waiting! }

      it { is_expected.to eq true }
    end

    context 'when the key is not present in redis' do
      before { status.delete! }

      it { is_expected.to eq false }
    end
  end
end
