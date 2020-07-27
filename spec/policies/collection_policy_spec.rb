# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionPolicy, type: :policy do
  subject { described_class }

  let(:collection) { instance_double 'Collection' }
  let(:user) { build(:user) }

  permissions :show? do
    context 'when the user has read access' do
      before { allow(collection).to receive(:read_access?).with(user).and_return(true) }

      it { is_expected.to permit(user, collection) }
    end

    context 'when the user does NOT have read access' do
      before { allow(collection).to receive(:read_access?).with(user).and_return(false) }

      it { is_expected.not_to permit(user, collection) }
    end

    context 'when the user is an admin' do
      let(:user) { build(:user, :admin) }

      before { allow(collection).to receive(:read_access?).with(user).and_return(false) }

      it { is_expected.to permit(user, collection) }
    end
  end
end
