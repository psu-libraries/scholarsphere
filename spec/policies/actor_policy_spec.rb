# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActorPolicy, type: :policy do
  subject { described_class }

  let(:user) { build(:user) }
  let(:admin) { build(:user, :admin) }
  let(:viewer) { build(:user, :viewer) }

  permissions :new?, :show?, :create? do
    it { is_expected.to permit(user) }
    it { is_expected.to permit(viewer) }
  end

  permissions :edit?, :update?, :destroy? do
    it { is_expected.not_to permit(user) }
    it { is_expected.to permit(admin) }
    it { is_expected.not_to permit(viewer) }
  end
end
