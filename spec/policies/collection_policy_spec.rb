# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionPolicy, type: :policy do
  let(:user) { instance_double 'User' }
  let(:collection) { instance_double 'Collection' }

  describe '#show?' do
    it 'delegates to Collection#read_access?' do
      allow(collection).to receive(:read_access?)
        .with(user).and_return(:whatever_read_access_returns)

      expect(described_class.new(user, collection).show?).to eq :whatever_read_access_returns
    end
  end
end
