# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Group do
  describe 'table' do
    it { is_expected.to have_db_column(:name) }
    it { is_expected.to have_db_index(:name) }
  end

  describe 'factory' do
    it { is_expected.to have_valid_factory(:group) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:access_controls) }
    it { is_expected.to have_many(:user_group_memberships) }
    it { is_expected.to have_many(:users).through(:user_group_memberships) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  end

  describe '.PUBLIC_AGENT_NAME' do
    subject { described_class::PUBLIC_AGENT_NAME }

    it { is_expected.to eq('public') }
  end

  describe '.public_agent' do
    subject { described_class.public_agent }

    its(:name) { is_expected.to eq(described_class::PUBLIC_AGENT_NAME) }
  end

  describe '#public_agent' do
    its(:public_agent) { is_expected.to eq(described_class.public_agent) }
  end

  describe '#public?' do
    context 'with the public group' do
      subject { described_class.public_agent }

      it { is_expected.to be_public }
    end

    context 'with any other group' do
      subject { described_class.new }

      it { is_expected.not_to be_public }
    end
  end

  describe '.AUTHORIZED_AGENT_NAME' do
    subject { described_class::AUTHORIZED_AGENT_NAME }

    it { is_expected.to eq('authorized') }
  end

  describe '.authorized_agent' do
    subject { described_class.authorized_agent }

    its(:name) { is_expected.to eq(described_class::AUTHORIZED_AGENT_NAME) }
  end

  describe '#authorized_agent' do
    its(:authorized_agent) { is_expected.to eq(described_class.authorized_agent) }
  end

  describe '#authorized?' do
    context 'with the authorized group' do
      subject { described_class.authorized_agent }

      it { is_expected.to be_authorized }
    end

    context 'with any other group' do
      subject { described_class.new }

      it { is_expected.not_to be_authorized }
    end
  end
end
