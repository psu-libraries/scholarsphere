# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Permissions do
  subject { resource }

  let(:resource) { build(:work) }

  it { is_expected.to respond_to(:discover_agents) }
  it { is_expected.to respond_to(:discover_users) }
  it { is_expected.to respond_to(:discover_groups) }
  it { is_expected.to respond_to(:read_agents) }
  it { is_expected.to respond_to(:read_users) }
  it { is_expected.to respond_to(:read_groups) }
  it { is_expected.to respond_to(:edit_agents) }
  it { is_expected.to respond_to(:edit_users) }
  it { is_expected.to respond_to(:edit_groups) }

  describe '#apply_open_access' do
    context 'when the resource is not open access' do
      it 'adds the necessary access controls to allow open access' do
        expect(resource.access_controls).to be_empty
        resource.apply_open_access
        expect(resource.access_controls.first.agent).to eq(Group.public_agent)
        expect(resource.access_controls.first.access_level).to eq(AccessControl::Level::READ)
      end
    end

    context 'when the resource already is open access' do
      let(:resource) { build(:work, :with_open_access) }

      it 'does not add a duplicate access control' do
        expect(resource.access_controls.map(&:agent)).to contain_exactly(Group.public_agent)
        resource.apply_open_access
        expect(resource.access_controls.map(&:agent)).to contain_exactly(Group.public_agent)
      end
    end
  end

  describe '#open_access?' do
    context 'with an open access resource' do
      let(:resource) { build(:work, :with_open_access) }

      it { is_expected.to be_open_access }
    end

    context 'when a restricted resource' do
      let(:resource) { build(:work) }

      it { is_expected.not_to be_open_access }
    end
  end

  describe '#apply_authorized_access' do
    context 'when the resource is not authorized access' do
      it 'adds the necessary access controls to allow authorized access' do
        expect(resource.access_controls).to be_empty
        resource.apply_authorized_access
        expect(resource.access_controls.first.agent).to eq(Group.authorized_agent)
        expect(resource.access_controls.first.access_level).to eq(AccessControl::Level::READ)
      end
    end

    context 'when the resource already has authorized access' do
      let(:resource) { build(:work, :with_authorized_access) }

      it 'does not add any duplicate access controls' do
        expect(resource.access_controls.map(&:agent)).to contain_exactly(Group.authorized_agent)
        resource.apply_authorized_access
        expect(resource.access_controls.map(&:agent)).to contain_exactly(Group.authorized_agent)
      end
    end
  end

  describe '#authorized?' do
    context 'with an autorized resource' do
      let(:resource) { build(:work, :with_authorized_access) }

      it { is_expected.to be_authorized_access }
    end

    context 'when a restricted resource' do
      let(:resource) { build(:work) }

      it { is_expected.not_to be_authorized_access }
    end
  end

  describe '#apply_discover_access' do
    before { resource.apply_discover_access(agent) }

    context 'with a group agent' do
      let(:agent) { build(:group) }

      its(:discover_groups) { is_expected.to contain_exactly(agent) }
    end

    context 'with a user agent' do
      let(:agent) { build(:user) }

      its(:discover_users) { is_expected.to contain_exactly(agent) }
    end

    context 'when a user already has discover access' do
      let(:agent) { build(:user) }

      it 'does not add any duplicate access controls' do
        expect(resource.access_controls.map(&:agent)).to contain_exactly(agent)
        resource.apply_discover_access(agent)
        expect(resource.access_controls.map(&:agent)).to contain_exactly(agent)
      end
    end

    context 'when a group already has discover access' do
      let(:agent) { build(:group) }

      it 'does not add any duplicate access controls' do
        expect(resource.access_controls.map(&:agent)).to contain_exactly(agent)
        resource.apply_discover_access(agent)
        expect(resource.access_controls.map(&:agent)).to contain_exactly(agent)
      end
    end
  end

  describe '#discover_access?' do
    context 'when a user has discover access to the resource' do
      let(:agent) { build(:user) }

      before { resource.apply_discover_access(agent) }

      specify { expect(resource.discover_access?(agent)).to be(true) }
    end

    context 'when a user does NOT have discover access to the resource' do
      let(:agent) { build(:user) }

      specify { expect(resource.discover_access?(agent)).to be(false) }
    end

    context 'when a group has discover access to the resource' do
      let(:agent) { build(:group) }

      before { resource.apply_discover_access(agent) }

      specify { expect(resource.discover_access?(agent)).to be(true) }
    end

    context 'when a group does NOT have discover access to the resource' do
      let(:agent) { build(:group) }

      specify { expect(resource.discover_access?(agent)).to be(false) }
    end
  end

  describe '#apply_read_access' do
    before { resource.apply_read_access(agent) }

    context 'with a group agent' do
      let(:agent) { build(:group) }

      its(:read_groups) { is_expected.to contain_exactly(agent) }
    end

    context 'with a user agent' do
      let(:agent) { build(:user) }

      its(:read_users) { is_expected.to contain_exactly(agent) }
    end

    context 'when a user already has read access' do
      let(:agent) { build(:user) }

      it 'does not add any duplicate access controls' do
        expect(resource.access_controls.map(&:agent)).to contain_exactly(agent)
        resource.apply_read_access(agent)
        expect(resource.access_controls.map(&:agent)).to contain_exactly(agent)
      end
    end

    context 'when a group already has read access' do
      let(:agent) { build(:group) }

      it 'does not add any duplicate access controls' do
        expect(resource.access_controls.map(&:agent)).to contain_exactly(agent)
        resource.apply_read_access(agent)
        expect(resource.access_controls.map(&:agent)).to contain_exactly(agent)
      end
    end
  end

  describe '#read_access?' do
    context 'when a user has read access to the resource' do
      let(:agent) { build(:user) }

      before { resource.apply_read_access(agent) }

      specify { expect(resource.read_access?(agent)).to be(true) }
    end

    context 'when a user does NOT have read access to the resource' do
      let(:agent) { build(:user) }

      specify { expect(resource.read_access?(agent)).to be(false) }
    end

    context 'when a group has read access to the resource' do
      let(:agent) { build(:group) }

      before { resource.apply_read_access(agent) }

      specify { expect(resource.read_access?(agent)).to be(true) }
    end

    context 'when a group does NOT have read access to the resource' do
      let(:agent) { build(:group) }

      specify { expect(resource.read_access?(agent)).to be(false) }
    end
  end

  describe '#apply_edit_access' do
    before { resource.apply_edit_access(agent) }

    context 'with a group agent' do
      let(:agent) { build(:group) }

      its(:edit_groups) { is_expected.to contain_exactly(agent) }
    end

    context 'with a user agent' do
      let(:agent) { build(:user) }

      its(:edit_users) { is_expected.to contain_exactly(agent, resource.depositor) }
    end

    context 'when a user already has edit access' do
      let(:agent) { build(:user) }

      it 'does not add any duplicate access controls' do
        expect(resource.access_controls.map(&:agent)).to contain_exactly(agent)
        resource.apply_edit_access(agent)
        expect(resource.access_controls.map(&:agent)).to contain_exactly(agent)
      end
    end

    context 'when a group already has edit access' do
      let(:agent) { build(:group) }

      it 'does not add any duplicate access controls' do
        expect(resource.access_controls.map(&:agent)).to contain_exactly(agent)
        resource.apply_edit_access(agent)
        expect(resource.access_controls.map(&:agent)).to contain_exactly(agent)
      end
    end
  end

  describe '#edit_access?' do
    context 'when a user has edit access to the resource' do
      let(:agent) { build(:user) }

      before { resource.apply_edit_access(agent) }

      specify { expect(resource.edit_access?(agent)).to be(true) }
    end

    context 'when a user does NOT have edit access to the resource' do
      let(:agent) { build(:user) }

      specify { expect(resource.edit_access?(agent)).to be(false) }
    end

    context 'when a group has edit access to the resource' do
      let(:agent) { build(:group) }

      before { resource.apply_edit_access(agent) }

      specify { expect(resource.edit_access?(agent)).to be(true) }
    end

    context 'when a group does NOT have edit access to the resource' do
      let(:agent) { build(:group) }

      specify { expect(resource.edit_access?(agent)).to be(false) }
    end
  end

  describe '#edit_users' do
    context 'when the depositor does NOT have edit access with an AccessControl object' do
      it 'is added to the list of users' do
        expect(resource.access_controls).to be_empty
        expect(resource.edit_users).to contain_exactly(resource.depositor)
      end
    end

    context 'when the depositor has edit access via an AccessControl object' do
      before { resource.apply_edit_access(resource.depositor) }

      it 'is not duplicated in the list of edit users' do
        expect(resource.edit_users).to contain_exactly(resource.depositor)
      end
    end
  end
end
