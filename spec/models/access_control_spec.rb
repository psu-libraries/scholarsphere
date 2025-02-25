# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccessControl do
  describe 'table' do
    it { is_expected.to have_db_column(:resource_type) }
    it { is_expected.to have_db_column(:resource_id) }
    it { is_expected.to have_db_column(:agent_type) }
    it { is_expected.to have_db_column(:agent_id) }
    it { is_expected.to have_db_column(:access_level) }
    it { is_expected.to have_db_index([:resource_type, :resource_id]) }
    it { is_expected.to have_db_index([:agent_type, :agent_id]) }
  end

  describe 'factories' do
    it { is_expected.to have_valid_factory(:access_control) }
    it { is_expected.to have_valid_factory(:access_control, :with_user) }
    it { is_expected.to have_valid_factory(:access_control, :with_group) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:agent) }
    it { is_expected.to belong_to(:resource) }
  end

  describe '#valid?' do
    subject { described_class.new(agent: agent, resource: resource, access_level: access_level) }

    let(:resource) { create(:work) }
    let(:agent) { create(:user) }
    let(:access_level) { AccessControl::Level::READ }

    context 'when specifying a duplicate type of access' do
      before { described_class.create(agent: agent, resource: resource, access_level: access_level) }

      it { is_expected.not_to be_valid }
    end

    context 'when specifying a different type of access' do
      before { described_class.create(agent: agent, resource: resource, access_level: AccessControl::Level::EDIT) }

      it { is_expected.to be_valid }
    end

    context 'when specifying an unsupported access level type' do
      let(:access_level) { 'bogus' }

      it { is_expected.not_to be_valid }
    end
  end

  describe '#public?' do
    subject { described_class.new(agent: agent, resource: resource, access_level: access_level) }

    let(:resource) { create(:work) }
    let(:access_level) { AccessControl::Level::READ }

    context 'when the access control defines public access' do
      let(:agent) { Group.public_agent }

      it { is_expected.to be_public }
    end

    context 'when the access control does NOT define public access' do
      let(:agent) { create(:group) }

      it { is_expected.not_to be_public }
    end
  end

  describe '#authorized?' do
    subject { described_class.new(agent: agent, resource: resource, access_level: access_level) }

    let(:resource) { create(:work) }
    let(:access_level) { AccessControl::Level::READ }

    context 'when the access control defines authorized access' do
      let(:agent) { Group.authorized_agent }

      it { is_expected.to be_authorized }
    end

    context 'when the access control does NOT define authorized access' do
      let(:agent) { create(:group) }

      it { is_expected.not_to be_authorized }
    end
  end

  describe 'AccessControl::Level' do
    specify { expect(AccessControl::Level::DISCOVER).to eq('discover') }
    specify { expect(AccessControl::Level::READ).to eq('read') }
    specify { expect(AccessControl::Level::EDIT).to eq('edit') }
    specify { expect(AccessControl::Level.default).to eq('discover') }
    specify { expect(AccessControl::Level.all).to contain_exactly('discover', 'read', 'edit') }
  end
end
