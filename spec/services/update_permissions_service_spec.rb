# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdatePermissionsService do
  let(:resource) { build(:work) }

  context 'when we want to create new groups' do
    context 'when the group does not exist' do
      it 'creates the new group from the permissions hash' do
        group_name = Faker::Currency.code.downcase
        described_class.call(resource: resource, permissions: { edit_groups: [group_name] }, create_agents: true)
        expect(resource.edit_groups.map(&:name)).to contain_exactly(group_name)
        expect { resource.save }.to change(Group, :count).by(1)
      end
    end

    context 'when the group does exist' do
      let!(:group) { create(:group) }

      it 'uses the existing group' do
        described_class.call(resource: resource, permissions: { edit_groups: [group.name] }, create_agents: true)
        expect(resource.edit_groups.map(&:name)).to contain_exactly(group.name)
        expect { resource.save }.to change(Group, :count).by(0)
      end
    end
  end

  context 'when we do NOT want to create new groups' do
    context 'when the group does NOT exist' do
      it 'does NOT add the group to the permissions' do
        group_name = Faker::Currency.code.downcase
        described_class.call(resource: resource, permissions: { edit_groups: [group_name] }, create_agents: false)
        expect(resource.edit_groups.map(&:name)).to be_empty
        expect { resource.save }.to change(Group, :count).by(0)
      end
    end

    context 'when the group does exist' do
      let!(:group) { create(:group) }

      it 'uses the existing group' do
        described_class.call(resource: resource, permissions: { edit_groups: [group.name] }, create_agents: false)
        expect(resource.edit_groups.map(&:name)).to contain_exactly(group.name)
        expect { resource.save }.to change(Group, :count).by(0)
      end
    end
  end

  context 'when we want to create new users' do
    context 'when the user does not exist' do
      it 'creates the new user from the permissions hash' do
        user_uid = build(:psu_oauth_response).uid
        expect {
          described_class.call(resource: resource, permissions: { edit_users: [user_uid] }, create_agents: true)
        }.to change(User, :count).by(1)
        expect(resource.edit_users.map(&:uid)).to contain_exactly(user_uid, resource.depositor.uid)
        expect { resource.save }.to change(User, :count).by(1)
      end
    end

    context 'when the user does exist' do
      let!(:user) { create(:user) }

      it 'uses the existing user' do
        expect {
          described_class.call(resource: resource, permissions: { edit_users: [user.uid] }, create_agents: true)
        }.to change(User, :count).by(0)
        expect(resource.edit_users.map(&:uid)).to contain_exactly(user.uid, resource.depositor.uid)
        expect { resource.save }.to change(User, :count).by(1)
      end
    end
  end

  context 'when we do NOT want to create new users' do
    context 'when the user does NOT exist' do
      it 'does NOT add the user to the permissions' do
        user_uid = build(:psu_oauth_response).uid
        expect {
          described_class.call(resource: resource, permissions: { edit_users: [user_uid] }, create_agents: false)
        }.to change(User, :count).by(0)
        expect(resource.edit_users.map(&:uid)).to contain_exactly(resource.depositor.uid)
        expect { resource.save }.to change(User, :count).by(1)
      end
    end

    context 'when the user does exist' do
      let!(:user) { create(:user) }

      it 'uses the existing user' do
        expect {
          described_class.call(resource: resource, permissions: { edit_users: [user.uid] }, create_agents: false)
        }.to change(User, :count).by(0)
        expect(resource.edit_users.map(&:uid)).to contain_exactly(user.uid, resource.depositor.uid)
        expect { resource.save }.to change(User, :count).by(1)
      end
    end
  end
end
