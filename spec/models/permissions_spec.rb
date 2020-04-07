# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Permissions do
  subject { resource }

  let(:resource) { build(:work, :with_no_access) }

  describe 'generated methods from PermissionsBuilder' do
    it { is_expected.to respond_to(:discover_agents) }
    it { is_expected.to respond_to(:discover_users) }
    it { is_expected.to respond_to(:discover_users=) }
    it { is_expected.to respond_to(:discover_groups) }
    it { is_expected.to respond_to(:discover_groups=) }
    it { is_expected.to respond_to(:read_agents) }
    it { is_expected.to respond_to(:read_users) }
    it { is_expected.to respond_to(:read_users=) }
    it { is_expected.to respond_to(:read_groups) }
    it { is_expected.to respond_to(:read_groups=) }
    it { is_expected.to respond_to(:edit_agents) }
    it { is_expected.to respond_to(:edit_users) }
    it { is_expected.to respond_to(:edit_users=) }
    it { is_expected.to respond_to(:edit_groups) }
    it { is_expected.to respond_to(:edit_groups=) }
  end

  describe Permissions::Visibility do
    specify { expect(Permissions::Visibility::OPEN).to eq('open') }
    specify { expect(Permissions::Visibility::AUTHORIZED).to eq('authenticated') }
    specify { expect(Permissions::Visibility::PRIVATE).to eq('restricted') }
    specify { expect(described_class.default).to eq('open') }
    specify { expect(described_class.all).to contain_exactly('open', 'authenticated', 'restricted') }
  end

  describe '#grant_open_access' do
    context 'when the resource is not open access' do
      it 'adds the necessary access controls to allow open access' do
        expect(resource.access_controls).to be_empty
        resource.grant_open_access
        expect(resource.access_controls.first.agent).to eq(Group.public_agent)
        expect(resource.access_controls.first.access_level).to eq(AccessControl::Level::READ)
      end
    end

    context 'when the resource already is open access' do
      let(:resource) { build(:work) }

      it 'does not add a duplicate access control' do
        expect(resource.access_controls.map(&:agent)).to contain_exactly(Group.public_agent)
        resource.grant_open_access
        expect(resource.access_controls.map(&:agent)).to contain_exactly(Group.public_agent)
      end
    end
  end

  describe '#revoke_open_access' do
    let(:resource) { build(:work) }

    it 'removes open access' do
      expect(resource.access_controls.map(&:agent)).to contain_exactly(Group.public_agent)
      resource.revoke_open_access
      expect(resource.access_controls).to be_empty
    end
  end

  describe '#open_access?' do
    context 'with an open access resource' do
      let(:resource) { build(:work) }

      it { is_expected.to be_open_access }
    end

    context 'with a restricted resource' do
      it { is_expected.not_to be_open_access }
    end

    context 'when the public agent does NOT have read access' do
      before { resource.grant_discover_access(Group.public_agent) }

      it { is_expected.not_to be_open_access }
    end
  end

  describe '#grant_authorized_access' do
    context 'when the resource is not authorized access' do
      it 'adds the necessary access controls to allow authorized access' do
        expect(resource.access_controls).to be_empty
        resource.grant_authorized_access
        expect(resource.access_controls.first.agent).to eq(Group.authorized_agent)
        expect(resource.access_controls.first.access_level).to eq(AccessControl::Level::READ)
      end
    end

    context 'when the resource already has authorized access' do
      let(:resource) { build(:work, visibility: Permissions::Visibility::AUTHORIZED) }

      it 'does not add any duplicate access controls' do
        expect(resource.access_controls.map(&:agent)).to contain_exactly(Group.authorized_agent)
        resource.grant_authorized_access
        expect(resource.access_controls.map(&:agent)).to contain_exactly(Group.authorized_agent)
      end
    end
  end

  describe '#revoke_authorized_access' do
    let(:resource) { build(:work, visibility: Permissions::Visibility::AUTHORIZED) }

    it 'removes authorized access' do
      expect(resource.access_controls.map(&:agent)).to contain_exactly(Group.authorized_agent)
      resource.revoke_authorized_access
      expect(resource.access_controls).to be_empty
    end
  end

  describe '#authorized?' do
    context 'with an autorized resource' do
      let(:resource) { build(:work, visibility: Permissions::Visibility::AUTHORIZED) }

      it { is_expected.to be_authorized_access }
    end

    context 'when a restricted resource' do
      let(:resource) { build(:work) }

      it { is_expected.not_to be_authorized_access }
    end

    context 'when the authorized agent does NOT have read access' do
      before { resource.grant_discover_access(Group.authorized_agent) }

      it { is_expected.not_to be_authorized_access }
    end
  end

  describe '#grant_discover_access' do
    before { resource.grant_discover_access(agent) }

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
        resource.grant_discover_access(agent)
        expect(resource.access_controls.map(&:agent)).to contain_exactly(agent)
      end
    end

    context 'when a group already has discover access' do
      let(:agent) { build(:group) }

      it 'does not add any duplicate access controls' do
        expect(resource.access_controls.map(&:agent)).to contain_exactly(agent)
        resource.grant_discover_access(agent)
        expect(resource.access_controls.map(&:agent)).to contain_exactly(agent)
      end
    end
  end

  describe '#revoke_discover_access' do
    let(:group_agent) { build(:group) }
    let(:user_agent) { build(:user) }

    before { resource.grant_discover_access(group_agent, user_agent) }

    context 'with a group agent' do
      it 'removes only the group agent' do
        expect(resource.access_controls.map(&:agent)).to contain_exactly(group_agent, user_agent)
        resource.revoke_discover_access(group_agent)
        expect(resource.access_controls.map(&:agent)).to contain_exactly(user_agent)
      end
    end

    context 'with a user agent' do
      it 'removes only the user agent' do
        expect(resource.access_controls.map(&:agent)).to contain_exactly(group_agent, user_agent)
        resource.revoke_discover_access(user_agent)
        expect(resource.access_controls.map(&:agent)).to contain_exactly(group_agent)
      end
    end
  end

  describe '#discover_access?' do
    context 'when a user has discover access to the resource' do
      let(:agent) { build(:user) }

      before { resource.grant_discover_access(agent) }

      specify { expect(resource.discover_access?(agent)).to be(true) }
    end

    context 'when a user does NOT have discover access to the resource' do
      let(:agent) { build(:user) }

      specify { expect(resource.discover_access?(agent)).to be(false) }
    end

    context 'when a group has discover access to the resource' do
      let(:agent) { build(:group) }

      before { resource.grant_discover_access(agent) }

      specify { expect(resource.discover_access?(agent)).to be(true) }
    end

    context 'when a group does NOT have discover access to the resource' do
      let(:agent) { build(:group) }

      specify { expect(resource.discover_access?(agent)).to be(false) }
    end

    context 'when a user is a member of a group with discover access' do
      let(:group) { build(:group) }
      let(:agent) { build(:user, groups: [group]) }

      before { resource.grant_discover_access(group) }

      specify { expect(resource.discover_access?(agent)).to be(true) }
    end
  end

  describe '#discover_users=' do
    let(:user1) { build(:user) }
    let(:user2) { build(:user) }

    before { resource.discover_users = [user1, user2] }

    context 'when setting new users' do
      its(:discover_users) { is_expected.to include(user1, user2) }
    end

    context 'when removing users' do
      before { resource.discover_users = [user2] }

      its(:discover_users) { is_expected.not_to include(user1) }
    end
  end

  describe '#discover_groups=' do
    let(:group1) { build(:group) }
    let(:group2) { build(:group) }

    before { resource.discover_groups = [group1, group2] }

    context 'when setting new groups' do
      its(:discover_groups) { is_expected.to include(group1, group2) }
    end

    context 'when removing groups' do
      before { resource.discover_groups = [group2] }

      its(:discover_groups) { is_expected.not_to include(group1) }
    end
  end

  describe '#grant_read_access' do
    before { resource.grant_read_access(agent) }

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
        resource.grant_read_access(agent)
        expect(resource.access_controls.map(&:agent)).to contain_exactly(agent)
      end
    end

    context 'when a group already has read access' do
      let(:agent) { build(:group) }

      it 'does not add any duplicate access controls' do
        expect(resource.access_controls.map(&:agent)).to contain_exactly(agent)
        resource.grant_read_access(agent)
        expect(resource.access_controls.map(&:agent)).to contain_exactly(agent)
      end
    end
  end

  describe '#revoke_read_access' do
    let(:group_agent) { build(:group) }
    let(:user_agent) { build(:user) }

    before { resource.grant_read_access(group_agent, user_agent) }

    context 'with a group agent' do
      it 'removes only the group agent' do
        expect(resource.access_controls.map(&:agent)).to contain_exactly(group_agent, user_agent)
        resource.revoke_read_access(group_agent)
        expect(resource.access_controls.map(&:agent)).to contain_exactly(user_agent)
      end
    end

    context 'with a user agent' do
      it 'removes only the user agent' do
        expect(resource.access_controls.map(&:agent)).to contain_exactly(group_agent, user_agent)
        resource.revoke_read_access(user_agent)
        expect(resource.access_controls.map(&:agent)).to contain_exactly(group_agent)
      end
    end
  end

  describe '#read_access?' do
    context 'when a user has read access to the resource' do
      let(:agent) { build(:user) }

      before { resource.grant_read_access(agent) }

      specify { expect(resource.read_access?(agent)).to be(true) }
    end

    context 'when a user does NOT have read access to the resource' do
      let(:agent) { build(:user) }

      specify { expect(resource.read_access?(agent)).to be(false) }
    end

    context 'when a group has read access to the resource' do
      let(:agent) { build(:group) }

      before { resource.grant_read_access(agent) }

      specify { expect(resource.read_access?(agent)).to be(true) }
    end

    context 'when a group does NOT have read access to the resource' do
      let(:agent) { build(:group) }

      specify { expect(resource.read_access?(agent)).to be(false) }
    end

    context 'when a user is a member of a group with read access' do
      let(:group) { build(:group) }
      let(:agent) { build(:user, groups: [group]) }

      before { resource.grant_read_access(group) }

      specify { expect(resource.read_access?(agent)).to be(true) }
    end
  end

  describe '#read_users=' do
    let(:user1) { build(:user) }
    let(:user2) { build(:user) }

    before { resource.read_users = [user1, user2] }

    context 'when setting new users' do
      its(:read_users) { is_expected.to include(user1, user2) }
    end

    context 'when removing users' do
      before { resource.read_users = [user2] }

      its(:read_users) { is_expected.not_to include(user1) }
    end
  end

  describe '#read_groups=' do
    let(:group1) { build(:group) }
    let(:group2) { build(:group) }

    before { resource.read_groups = [group1, group2] }

    context 'when setting new groups' do
      its(:read_groups) { is_expected.to include(group1, group2) }
    end

    context 'when removing groups' do
      before { resource.read_groups = [group2] }

      its(:read_groups) { is_expected.not_to include(group1) }
    end

    context 'with a public resource' do
      let(:resource) { build(:work, visibility: Permissions::Visibility::OPEN) }

      its(:read_groups) { is_expected.to contain_exactly(group1, group2, Group.public_agent) }
    end

    context 'with an authorized resource' do
      let(:resource) { build(:work, visibility: Permissions::Visibility::AUTHORIZED) }

      its(:read_groups) { is_expected.to contain_exactly(group1, group2, Group.authorized_agent) }
    end

    context 'with a private resource' do
      let(:resource) { build(:work, visibility: Permissions::Visibility::PRIVATE) }

      its(:read_groups) { is_expected.to contain_exactly(group1, group2) }

      specify 'there is no nil access control from the null visibility agent' do
        expect(resource.access_controls.length).to eq(2)
      end
    end
  end

  describe '#grant_edit_access' do
    before { resource.grant_edit_access(agent) }

    context 'with a group agent' do
      let(:agent) { build(:group) }

      its(:edit_groups) { is_expected.to contain_exactly(agent) }
    end

    context 'with a user agent' do
      let(:agent) { build(:user) }

      its(:edit_users) { is_expected.to contain_exactly(agent, resource.depositor.user) }
    end

    context 'when a user already has edit access' do
      let(:agent) { build(:user) }

      it 'does not add any duplicate access controls' do
        expect(resource.access_controls.map(&:agent)).to contain_exactly(agent)
        resource.grant_edit_access(agent)
        expect(resource.access_controls.map(&:agent)).to contain_exactly(agent)
      end
    end

    context 'when a group already has edit access' do
      let(:agent) { build(:group) }

      it 'does not add any duplicate access controls' do
        expect(resource.access_controls.map(&:agent)).to contain_exactly(agent)
        resource.grant_edit_access(agent)
        expect(resource.access_controls.map(&:agent)).to contain_exactly(agent)
      end
    end
  end

  describe '#revoke_edit_access' do
    let(:group_agent) { build(:group) }
    let(:user_agent) { build(:user) }

    before { resource.grant_edit_access(group_agent, user_agent) }

    context 'with a group agent' do
      it 'removes only the group agent' do
        expect(resource.access_controls.map(&:agent)).to contain_exactly(group_agent, user_agent)
        resource.revoke_edit_access(group_agent)
        expect(resource.access_controls.map(&:agent)).to contain_exactly(user_agent)
      end
    end

    context 'with a user agent' do
      it 'removes only the user agent' do
        expect(resource.access_controls.map(&:agent)).to contain_exactly(group_agent, user_agent)
        resource.revoke_edit_access(user_agent)
        expect(resource.access_controls.map(&:agent)).to contain_exactly(group_agent)
      end
    end
  end

  describe '#edit_access?' do
    context 'when a user has edit access to the resource' do
      let(:agent) { build(:user) }

      before { resource.grant_edit_access(agent) }

      specify { expect(resource.edit_access?(agent)).to be(true) }
    end

    context 'when a user does NOT have edit access to the resource' do
      let(:agent) { build(:user) }

      specify { expect(resource.edit_access?(agent)).to be(false) }
    end

    context 'when a group has edit access to the resource' do
      let(:agent) { build(:group) }

      before { resource.grant_edit_access(agent) }

      specify { expect(resource.edit_access?(agent)).to be(true) }
    end

    context 'when a group does NOT have edit access to the resource' do
      let(:agent) { build(:group) }

      specify { expect(resource.edit_access?(agent)).to be(false) }
    end

    context 'when a user is a member of a group with edit access' do
      let(:group) { build(:group) }
      let(:agent) { build(:user, groups: [group]) }

      before { resource.grant_edit_access(group) }

      specify { expect(resource.edit_access?(agent)).to be(true) }
    end
  end

  describe '#edit_users' do
    context 'when the depositor does NOT have edit access with an AccessControl object' do
      it 'is added to the list of users' do
        expect(resource.access_controls).to be_empty
        expect(resource.edit_users).to contain_exactly(resource.depositor.user)
      end
    end

    context 'when the depositor has edit access via an AccessControl object' do
      before { resource.grant_edit_access(resource.depositor.user) }

      it 'is not duplicated in the list of edit users' do
        expect(resource.edit_users).to contain_exactly(resource.depositor.user)
      end
    end
  end

  describe '#edit_users=' do
    let(:user1) { build(:user) }
    let(:user2) { build(:user) }

    before { resource.edit_users = [user1, user2] }

    context 'when setting new users' do
      its(:edit_users) { is_expected.to include(user1, user2) }
    end

    context 'when removing users' do
      before { resource.edit_users = [user2] }

      its(:edit_users) { is_expected.not_to include(user1) }
    end

    context 'when the depositor is an argument' do
      it 'does not create an access control for the depositor' do
        expect(resource.access_controls.map(&:agent)).to contain_exactly(user1, user2)
        resource.edit_users = [user1, resource.depositor.user]
        expect(resource.access_controls.map(&:agent)).to contain_exactly(user1)
      end
    end
  end

  describe '#edit_groups=' do
    let(:group1) { build(:group) }
    let(:group2) { build(:group) }

    before { resource.edit_groups = [group1, group2] }

    context 'when setting new groups' do
      its(:edit_groups) { is_expected.to include(group1, group2) }
    end

    context 'when removing groups' do
      before { resource.edit_groups = [group2] }

      its(:edit_groups) { is_expected.not_to include(group1) }
    end
  end

  describe '#visibility' do
    context 'with open visibility' do
      let(:resource) { build(:work, visibility: Permissions::Visibility::OPEN) }

      its(:visibility) { is_expected.to eq(Permissions::Visibility::OPEN) }
    end

    context 'with authorized visibility' do
      let(:resource) { build(:work, visibility: Permissions::Visibility::AUTHORIZED) }

      its(:visibility) { is_expected.to eq(Permissions::Visibility::AUTHORIZED) }
    end

    context 'with private visibility' do
      let(:resource) { build(:work, visibility: Permissions::Visibility::PRIVATE) }

      its(:visibility) { is_expected.to eq(Permissions::Visibility::PRIVATE) }
    end

    context 'with an unsupported visibility' do
      it 'raises an argument error' do
        expect { resource.visibility = 'bogus' }.to raise_error(ArgumentError, 'bogus is not a supported visibility')
      end
    end
  end
end
