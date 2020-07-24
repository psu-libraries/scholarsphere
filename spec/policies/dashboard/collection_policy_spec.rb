# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::CollectionPolicy, type: :policy do
  subject(:policy) { described_class }

  let(:user) { create :user }
  let(:other_user) { create :user }
  let(:admin) { create :user, :admin }

  let!(:my_collection) { create :collection, depositor: user.actor }

  permissions '.scope' do
    let(:scoped_collections) { described_class::Scope.new(user, Collection).resolve }

    before do
      create :collection, depositor: other_user.actor
    end

    it 'only finds my collections' do
      expect(scoped_collections).to match_array([my_collection])
    end
  end

  permissions :show?, :edit?, :update?, :destroy? do
    it { is_expected.to permit(user, my_collection) }
    it { is_expected.not_to permit(other_user, my_collection) }
    it { is_expected.to permit(admin, my_collection) }
  end
end
