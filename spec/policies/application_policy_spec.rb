# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationPolicy, type: :policy do
  subject { described_class }

  let(:record) { instance_double 'Work' }

  permissions :index?, :show?, :create?, :new?, :update?, :edit?, :destroy? do
    context 'with an admin user' do
      let(:user) { build(:user, :admin) }

      it { is_expected.to permit(user, record) }
    end

    context 'with an authenticated user' do
      let(:user) { build(:user) }

      it { is_expected.not_to permit(user, record) }
    end
  end

  describe ApplicationPolicy::Scope do
    it 'raises an error if #limit is not defined' do
      expect {
        described_class.new('user', 'model')
      }.to raise_error(NoMethodError, 'ApplicationPolicy::Scope#limit must be defined instead of #resolve')
    end
  end
end
