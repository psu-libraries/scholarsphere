# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkPolicy, type: :policy do
  subject { described_class }

  let(:work) { instance_double 'Work' }
  let(:user) { build(:user) }

  permissions :show? do
    context 'when the user has discover access' do
      before { allow(work).to receive(:discover_access?).with(user).and_return(true) }

      it { is_expected.to permit(user, work) }
    end

    context 'when the user does NOT have discover access' do
      before { allow(work).to receive(:discover_access?).with(user).and_return(false) }

      it { is_expected.not_to permit(user, work) }
    end

    context 'when the user is an admin' do
      let(:user) { build(:user, :admin) }

      before { allow(work).to receive(:discover_access?).with(user).and_return(false) }

      it { is_expected.to permit(user, work) }
    end
  end
end
