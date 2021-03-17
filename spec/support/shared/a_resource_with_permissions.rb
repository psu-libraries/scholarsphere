# frozen_string_literal: true

RSpec.shared_examples 'a resource with permissions' do
  before(:all) do
    raise 'factory_name must be set with `let(:factory_name)`' unless defined? factory_name
  end

  let(:open_access_resource) { build(factory_name, visibility: Permissions::Visibility::OPEN) }
  let(:authorized_resource) { build(factory_name, visibility: Permissions::Visibility::AUTHORIZED) }
  let(:private_resource) { build(factory_name).tap { |resource| resource.access_controls.destroy_all } }

  describe 'generated methods from PermissionsBuilder' do
    subject { open_access_resource }

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

  describe '#grant_open_access' do
    context 'when the resource is not open access' do
      subject(:resource) { private_resource }

      it 'adds the necessary access controls to allow open access' do
        expect(resource.access_controls).to be_empty
        resource.grant_open_access
        expect(resource.access_controls).to contain_exactly(
          an_access_control_for(agent: Group.public_agent, access_level: AccessControl::Level::READ),
          an_access_control_for(agent: Group.public_agent, access_level: AccessControl::Level::DISCOVER)
        )
      end
    end

    context 'when the resource already is open access' do
      subject(:resource) { open_access_resource }

      it 'does not add a duplicate access control' do
        expect(resource.access_controls).to contain_exactly(
          an_access_control_for(agent: Group.public_agent, access_level: AccessControl::Level::READ),
          an_access_control_for(agent: Group.public_agent, access_level: AccessControl::Level::DISCOVER)
        )
        resource.grant_open_access
        expect(resource.access_controls).to contain_exactly(
          an_access_control_for(agent: Group.public_agent, access_level: AccessControl::Level::READ),
          an_access_control_for(agent: Group.public_agent, access_level: AccessControl::Level::DISCOVER)
        )
      end
    end
  end

  describe '#revoke_open_access' do
    subject(:resource) { open_access_resource }

    it 'removes open access' do
      expect(resource.access_controls).to contain_exactly(
        an_access_control_for(agent: Group.public_agent, access_level: AccessControl::Level::READ),
        an_access_control_for(agent: Group.public_agent, access_level: AccessControl::Level::DISCOVER)
      )
      resource.revoke_open_access
      expect(resource.access_controls).to be_empty
    end
  end

  describe '#open_access?' do
    context 'with an open access resource' do
      subject(:resource) { open_access_resource }

      it { is_expected.to be_open_access }
    end

    context 'with a restricted resource' do
      subject(:resource) { private_resource }

      it { is_expected.not_to be_open_access }
    end

    context 'when the public agent ONLY has discover access' do
      subject(:resource) { private_resource }

      before { resource.grant_discover_access(Group.public_agent) }

      it { is_expected.not_to be_open_access }
    end
  end

  describe '#grant_authorized_access' do
    context 'when the resource is not authorized access' do
      subject(:resource) { private_resource }

      it 'adds the necessary access controls to allow authorized access' do
        expect(resource.access_controls).to be_empty
        resource.grant_authorized_access
        expect(resource.access_controls).to contain_exactly(
          an_access_control_for(agent: Group.authorized_agent, access_level: AccessControl::Level::READ),
          an_access_control_for(agent: Group.authorized_agent, access_level: AccessControl::Level::DISCOVER),
          an_access_control_for(agent: Group.public_agent, access_level: AccessControl::Level::DISCOVER)
        )
      end
    end

    context 'when the resource already has authorized access' do
      subject(:resource) { authorized_resource }

      it 'does not add any duplicate access controls' do
        expect(resource.access_controls).to contain_exactly(
          an_access_control_for(agent: Group.authorized_agent, access_level: AccessControl::Level::READ),
          an_access_control_for(agent: Group.authorized_agent, access_level: AccessControl::Level::DISCOVER),
          an_access_control_for(agent: Group.public_agent, access_level: AccessControl::Level::DISCOVER)
        )
        resource.grant_authorized_access
        expect(resource.access_controls).to contain_exactly(
          an_access_control_for(agent: Group.authorized_agent, access_level: AccessControl::Level::READ),
          an_access_control_for(agent: Group.authorized_agent, access_level: AccessControl::Level::DISCOVER),
          an_access_control_for(agent: Group.public_agent, access_level: AccessControl::Level::DISCOVER)
        )
      end
    end
  end

  describe '#revoke_authorized_access' do
    subject(:resource) { authorized_resource }

    it 'removes authorized access' do
      expect(resource.access_controls).to contain_exactly(
        an_access_control_for(agent: Group.authorized_agent, access_level: AccessControl::Level::READ),
        an_access_control_for(agent: Group.authorized_agent, access_level: AccessControl::Level::DISCOVER),
        an_access_control_for(agent: Group.public_agent, access_level: AccessControl::Level::DISCOVER)
      )
      resource.revoke_authorized_access
      expect(resource.access_controls).to be_empty
    end
  end

  describe '#authorized?' do
    context 'with an autorized resource' do
      subject(:resource) { authorized_resource }

      it { is_expected.to be_authorized_access }
    end

    context 'when a restricted resource' do
      subject(:resource) { private_resource }

      it { is_expected.not_to be_authorized_access }
    end

    context 'when the authorized agent ONLY has discover access' do
      subject(:resource) { open_access_resource }

      before { resource.grant_discover_access(Group.authorized_agent) }

      it { is_expected.not_to be_authorized_access }
    end
  end

  describe '#grant_discover_access' do
    subject(:resource) { private_resource }

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
    subject(:resource) { private_resource }

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
    subject(:resource) { private_resource }

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
    subject(:resource) { private_resource }

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
    subject(:resource) { private_resource }

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
    subject(:resource) { private_resource }

    before { resource.grant_read_access(agent) }

    context 'with a group agent' do
      let(:agent) { build(:group) }

      its(:read_groups) { is_expected.to contain_exactly(agent) }
      its(:discover_groups) { is_expected.to contain_exactly(agent) }
    end

    context 'with a user agent' do
      let(:agent) { build(:user) }

      its(:read_users) { is_expected.to contain_exactly(agent) }
      its(:discover_users) { is_expected.to contain_exactly(agent) }
    end

    context 'when a user already has read access' do
      let(:agent) { build(:user) }

      it 'does not add any duplicate access controls' do
        expect(resource.access_controls).to contain_exactly(
          an_access_control_for(agent: agent, access_level: AccessControl::Level::DISCOVER),
          an_access_control_for(agent: agent, access_level: AccessControl::Level::READ)
        )
        resource.grant_read_access(agent)
        expect(resource.access_controls).to contain_exactly(
          an_access_control_for(agent: agent, access_level: AccessControl::Level::DISCOVER),
          an_access_control_for(agent: agent, access_level: AccessControl::Level::READ)
        )
      end
    end

    context 'when a group already has read access' do
      let(:agent) { build(:group) }

      it 'does not add any duplicate access controls' do
        expect(resource.access_controls).to contain_exactly(
          an_access_control_for(agent: agent, access_level: AccessControl::Level::DISCOVER),
          an_access_control_for(agent: agent, access_level: AccessControl::Level::READ)
        )
        resource.grant_read_access(agent)
        expect(resource.access_controls).to contain_exactly(
          an_access_control_for(agent: agent, access_level: AccessControl::Level::DISCOVER),
          an_access_control_for(agent: agent, access_level: AccessControl::Level::READ)
        )
      end
    end
  end

  describe '#revoke_read_access' do
    subject(:resource) { private_resource }

    let(:group_agent) { build(:group) }
    let(:user_agent) { build(:user) }

    before { resource.grant_read_access(group_agent, user_agent) }

    context 'with a group agent' do
      it 'removes only the group agent' do
        expect(resource.access_controls).to contain_exactly(
          an_access_control_for(agent: user_agent, access_level: AccessControl::Level::DISCOVER),
          an_access_control_for(agent: user_agent, access_level: AccessControl::Level::READ),
          an_access_control_for(agent: group_agent, access_level: AccessControl::Level::DISCOVER),
          an_access_control_for(agent: group_agent, access_level: AccessControl::Level::READ)
        )
        resource.revoke_read_access(group_agent)
        expect(resource.access_controls).to contain_exactly(
          an_access_control_for(agent: user_agent, access_level: AccessControl::Level::DISCOVER),
          an_access_control_for(agent: user_agent, access_level: AccessControl::Level::READ)
        )
      end
    end

    context 'with a user agent' do
      it 'removes only the user agent' do
        expect(resource.access_controls).to contain_exactly(
          an_access_control_for(agent: user_agent, access_level: AccessControl::Level::DISCOVER),
          an_access_control_for(agent: user_agent, access_level: AccessControl::Level::READ),
          an_access_control_for(agent: group_agent, access_level: AccessControl::Level::DISCOVER),
          an_access_control_for(agent: group_agent, access_level: AccessControl::Level::READ)
        )
        resource.revoke_read_access(user_agent)
        expect(resource.access_controls).to contain_exactly(
          an_access_control_for(agent: group_agent, access_level: AccessControl::Level::DISCOVER),
          an_access_control_for(agent: group_agent, access_level: AccessControl::Level::READ)
        )
      end
    end
  end

  describe '#read_access?' do
    subject(:resource) { private_resource }

    context 'when a user has read access to the resource' do
      let(:agent) { build(:user) }

      before { resource.grant_read_access(agent) }

      specify do
        expect(resource.read_access?(agent)).to be(true)
        expect(resource.discover_access?(agent)).to be(true)
      end
    end

    context 'when a user does NOT have read access to the resource' do
      let(:agent) { build(:user) }

      specify do
        expect(resource.read_access?(agent)).to be(false)
        expect(resource.discover_access?(agent)).to be(false)
      end
    end

    context 'when a group has read access to the resource' do
      let(:agent) { build(:group) }

      before { resource.grant_read_access(agent) }

      specify do
        expect(resource.read_access?(agent)).to be(true)
        expect(resource.discover_access?(agent)).to be(true)
      end
    end

    context 'when a group does NOT have read access to the resource' do
      let(:agent) { build(:group) }

      specify do
        expect(resource.read_access?(agent)).to be(false)
        expect(resource.discover_access?(agent)).to be(false)
      end
    end

    context 'when a user is a member of a group with read access' do
      let(:group) { build(:group) }
      let(:agent) { build(:user, groups: [group]) }

      before { resource.grant_read_access(group) }

      specify do
        expect(resource.read_access?(agent)).to be(true)
        expect(resource.discover_access?(agent)).to be(true)
      end
    end
  end

  describe '#read_users=' do
    subject(:resource) { private_resource }

    let(:user1) { build(:user) }
    let(:user2) { build(:user) }

    before { resource.read_users = [user1, user2] }

    context 'when setting new users' do
      its(:read_users) { is_expected.to include(user1, user2) }
      its(:discover_users) { is_expected.to include(user1, user2) }
    end

    context 'when removing users' do
      before { resource.read_users = [user2] }

      its(:read_users) { is_expected.not_to include(user1) }
      its(:discover_users) { is_expected.not_to include(user1) }
    end
  end

  describe '#read_groups=' do
    subject(:resource) { open_access_resource }

    let(:group1) { build(:group) }
    let(:group2) { build(:group) }

    before { resource.read_groups = [group1, group2] }

    context 'when setting new groups' do
      its(:read_groups) { is_expected.to include(group1, group2) }
      its(:discover_groups) { is_expected.to include(group1, group2) }
    end

    context 'when removing groups' do
      before { resource.read_groups = [group2] }

      its(:read_groups) { is_expected.not_to include(group1) }
      its(:discover_groups) { is_expected.not_to include(group1) }
    end

    context 'with a public resource' do
      subject(:resource) { open_access_resource }

      its(:read_groups) { is_expected.to contain_exactly(group1, group2, Group.public_agent) }
      its(:discover_groups) { is_expected.to contain_exactly(group1, group2, Group.public_agent) }
    end

    context 'with an authorized resource' do
      subject(:resource) { authorized_resource }

      its(:read_groups) { is_expected.to contain_exactly(group1, group2, Group.authorized_agent) }

      its(:discover_groups) do
        is_expected.to contain_exactly(group1, group2, Group.authorized_agent, Group.public_agent)
      end
    end

    context 'with a private resource' do
      subject(:resource) { private_resource }

      its(:read_groups) { is_expected.to contain_exactly(group1, group2) }

      specify 'there is no nil access control from the null visibility agent' do
        expect(resource.access_controls.length).to eq(4)
      end
    end
  end

  describe '#grant_edit_access' do
    subject(:resource) { private_resource }

    before { resource.grant_edit_access(agent) }

    context 'with a group agent' do
      let(:agent) { build(:group) }

      its(:edit_groups) { is_expected.to contain_exactly(agent) }
      its(:read_groups) { is_expected.to contain_exactly(agent) }
      its(:discover_groups) { is_expected.to contain_exactly(agent) }
    end

    context 'with a user agent' do
      let(:agent) { build(:user) }

      its(:edit_users) { is_expected.to contain_exactly(agent) }
      its(:read_users) { is_expected.to contain_exactly(agent) }
      its(:discover_users) { is_expected.to contain_exactly(agent) }
    end

    context 'when a user already has edit access' do
      let(:agent) { build(:user) }

      it 'does not add any duplicate access controls' do
        expect(resource.access_controls).to contain_exactly(
          an_access_control_for(agent: agent, access_level: AccessControl::Level::DISCOVER),
          an_access_control_for(agent: agent, access_level: AccessControl::Level::READ),
          an_access_control_for(agent: agent, access_level: AccessControl::Level::EDIT)
        )
        resource.grant_edit_access(agent)
        expect(resource.access_controls).to contain_exactly(
          an_access_control_for(agent: agent, access_level: AccessControl::Level::DISCOVER),
          an_access_control_for(agent: agent, access_level: AccessControl::Level::READ),
          an_access_control_for(agent: agent, access_level: AccessControl::Level::EDIT)
        )
      end
    end

    context 'when a group already has edit access' do
      let(:agent) { build(:group) }

      it 'does not add any duplicate access controls' do
        expect(resource.access_controls).to contain_exactly(
          an_access_control_for(agent: agent, access_level: AccessControl::Level::DISCOVER),
          an_access_control_for(agent: agent, access_level: AccessControl::Level::READ),
          an_access_control_for(agent: agent, access_level: AccessControl::Level::EDIT)
        )
        resource.grant_edit_access(agent)
        expect(resource.access_controls).to contain_exactly(
          an_access_control_for(agent: agent, access_level: AccessControl::Level::DISCOVER),
          an_access_control_for(agent: agent, access_level: AccessControl::Level::READ),
          an_access_control_for(agent: agent, access_level: AccessControl::Level::EDIT)
        )
      end
    end
  end

  describe '#revoke_edit_access' do
    subject(:resource) { private_resource }

    let(:group_agent) { build(:group) }
    let(:user_agent) { build(:user) }

    before { resource.grant_edit_access(group_agent, user_agent) }

    context 'with a group agent' do
      it 'removes only the group agent' do
        expect(resource.access_controls).to contain_exactly(
          an_access_control_for(agent: group_agent, access_level: AccessControl::Level::DISCOVER),
          an_access_control_for(agent: group_agent, access_level: AccessControl::Level::READ),
          an_access_control_for(agent: group_agent, access_level: AccessControl::Level::EDIT),
          an_access_control_for(agent: user_agent, access_level: AccessControl::Level::DISCOVER),
          an_access_control_for(agent: user_agent, access_level: AccessControl::Level::READ),
          an_access_control_for(agent: user_agent, access_level: AccessControl::Level::EDIT)
        )
        resource.revoke_edit_access(group_agent)
        expect(resource.access_controls).to contain_exactly(
          an_access_control_for(agent: user_agent, access_level: AccessControl::Level::DISCOVER),
          an_access_control_for(agent: user_agent, access_level: AccessControl::Level::READ),
          an_access_control_for(agent: user_agent, access_level: AccessControl::Level::EDIT)
        )
      end
    end

    context 'with a user agent' do
      it 'removes only the user agent' do
        expect(resource.access_controls).to contain_exactly(
          an_access_control_for(agent: group_agent, access_level: AccessControl::Level::DISCOVER),
          an_access_control_for(agent: group_agent, access_level: AccessControl::Level::READ),
          an_access_control_for(agent: group_agent, access_level: AccessControl::Level::EDIT),
          an_access_control_for(agent: user_agent, access_level: AccessControl::Level::DISCOVER),
          an_access_control_for(agent: user_agent, access_level: AccessControl::Level::READ),
          an_access_control_for(agent: user_agent, access_level: AccessControl::Level::EDIT)
        )
        resource.revoke_edit_access(user_agent)
        expect(resource.access_controls).to contain_exactly(
          an_access_control_for(agent: group_agent, access_level: AccessControl::Level::DISCOVER),
          an_access_control_for(agent: group_agent, access_level: AccessControl::Level::READ),
          an_access_control_for(agent: group_agent, access_level: AccessControl::Level::EDIT)
        )
      end
    end
  end

  describe '#edit_access?' do
    subject(:resource) { open_access_resource }

    context 'when a user has edit access to the resource' do
      let(:agent) { build(:user) }

      before { resource.grant_edit_access(agent) }

      specify do
        expect(resource.edit_access?(agent)).to be(true)
        expect(resource.read_access?(agent)).to be(true)
        expect(resource.discover_access?(agent)).to be(true)
      end
    end

    context 'when a user does NOT have edit access to the resource' do
      let(:agent) { build(:user) }

      specify 'no edit access is granted' do
        expect(resource.edit_access?(agent)).to be(false)
      end

      specify 'open access is still granted' do
        expect(resource.read_access?(agent)).to be(true)
        expect(resource.discover_access?(agent)).to be(true)
      end
    end

    context 'when a group has edit access to the resource' do
      let(:agent) { build(:group) }

      before { resource.grant_edit_access(agent) }

      specify do
        expect(resource.edit_access?(agent)).to be(true)
        expect(resource.read_access?(agent)).to be(true)
        expect(resource.discover_access?(agent)).to be(true)
      end
    end

    context 'when a group does NOT have edit access to the resource' do
      let(:agent) { build(:group) }

      specify do
        expect(resource.edit_access?(agent)).to be(false)
        expect(resource.read_access?(agent)).to be(false)
        expect(resource.discover_access?(agent)).to be(false)
      end
    end

    context 'when a user is a member of a group with edit access' do
      let(:group) { build(:group) }
      let(:agent) { build(:user, groups: [group]) }

      before { resource.grant_edit_access(group) }

      specify do
        expect(resource.edit_access?(agent)).to be(true)
        expect(resource.read_access?(agent)).to be(true)
        expect(resource.discover_access?(agent)).to be(true)
      end
    end
  end

  describe '#edit_users' do
    subject(:resource) { private_resource }

    context 'when the depositor does NOT have edit access with an AccessControl object' do
      it 'is added to the list of users' do
        expect(resource.access_controls).to be_empty
        expect(resource.edit_users).to be_empty
      end
    end

    context 'when the depositor has edit access via an AccessControl object' do
      before { resource.grant_edit_access(resource.depositor.user) }

      it 'is not duplicated in the list of edit users' do
        expect(resource.edit_users).to contain_exactly(resource.depositor.user)
      end
    end

    context 'when the depositor is not attached to a user' do
      before { resource.depositor = build(:actor) }

      it 'is NOT added to the list of users' do
        expect(resource.edit_users).to be_empty
      end
    end
  end

  describe '#edit_users=' do
    subject(:resource) { private_resource }

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
  end

  describe '#edit_groups=' do
    subject(:resource) { private_resource }

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
      subject(:resource) { build(factory_name, visibility: Permissions::Visibility::OPEN) }

      its(:visibility) { is_expected.to eq(Permissions::Visibility::OPEN) }
    end

    context 'with authorized visibility' do
      subject(:resource) { build(factory_name, visibility: Permissions::Visibility::AUTHORIZED) }

      its(:visibility) { is_expected.to eq(Permissions::Visibility::AUTHORIZED) }
    end

    context 'with private visibility' do
      subject(:resource) { build(factory_name, visibility: Permissions::Visibility::PRIVATE) }

      its(:visibility) { is_expected.to eq(Permissions::Visibility::PRIVATE) }
    end

    context 'with an unsupported visibility' do
      subject(:resource) { build(factory_name, visibility: 'bogus') }

      let(:default) { factory_name.to_s.capitalize.constantize.new }

      its(:visibility) { is_expected.to eq(default.visibility) }
    end
  end
end
