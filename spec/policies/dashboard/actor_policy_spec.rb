# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::ActorPolicy, type: :policy do
  subject { described_class }

  let(:user) { build(:user) }
  let(:admin) { build(:user, :admin) }

  permissions :new?, :show?, :create? do
    it { is_expected.to permit(user) }
  end

  permissions :edit?, :update?, :destroy? do
    it { is_expected.not_to permit(user) }
    it { is_expected.to permit(admin) }
  end
end
