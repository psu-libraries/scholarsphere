# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionPolicy, type: :policy do
  let(:user) { instance_double 'User' }
  let(:collection) { instance_double 'Collection' }

  describe '#show?' do
    it 'is always true' do
      expect(described_class.new(user, collection).show?).to eq true
    end
  end
end
