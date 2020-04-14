# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdatePermissionsService do
  let(:resource) { build(:work) }

  context 'when we allow new groups to be created' do
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

  context 'when we allow new users to be created' do
    context 'with a user who is currently at Penn State' do
      let(:mock_client) { instance_spy('PennState::SearchService::Client') }
      let(:person) { create(:person) }

      before do
        allow(PennState::SearchService::Client).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:userid).with(person.user_id).and_return(person)
      end

      context 'when the user does NOT exist in the database' do
        it 'creates the new user from the permissions hash' do
          expect {
            described_class.call(resource: resource, permissions: { edit_users: [person.user_id] }, create_agents: true)
          }.to change(User, :count).by(1)
        end

        it 'creates a new actor linked to the user' do
          expect {
            described_class.call(resource: resource, permissions: { edit_users: [person.user_id] }, create_agents: true)
          }.to change(Actor, :count).by(1)
          actor = Actor.find_by(psu_id: person.user_id)
          expect(actor.user.access_id).to eq(person.user_id)
        end

        it 'adds a new access control to the resource' do
          expect(resource.edit_users.map(&:uid)).not_to include(person.user_id)
          described_class.call(resource: resource, permissions: { edit_users: [person.user_id] }, create_agents: true)
          expect(resource.edit_users.map(&:uid)).to include(person.user_id)
        end
      end

      context 'when the user already exists in the database' do
        let!(:user) { create(:user, access_id: person.user_id) }

        it 'does NOT create a new user from the permissions hash' do
          expect {
            described_class.call(resource: resource, permissions: { edit_users: [user.access_id] }, create_agents: true)
          }.not_to change(User, :count)
        end

        it 'does NOT create a new actor' do
          expect {
            described_class.call(resource: resource, permissions: { edit_users: [user.access_id] }, create_agents: true)
          }.not_to change(Actor, :count)
        end

        it 'adds a new access control using the existing user' do
          expect(resource.edit_users.map(&:uid)).not_to include(user.access_id)
          described_class.call(resource: resource, permissions: { edit_users: [user.access_id] }, create_agents: true)
          expect(resource.edit_users.map(&:uid)).to include(user.access_id)
        end
      end
    end

    context 'with a user who is NOT at Penn State' do
      let(:mock_client) { instance_spy('PennState::SearchService::Client') }
      let(:person) { create(:person) }

      before do
        allow(PennState::SearchService::Client).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:userid).with(person.user_id).and_return(nil)
      end

      context 'when the user does NOT exist in the database' do
        it 'does NOT create a new user from the permissions hash' do
          expect {
            described_class.call(resource: resource, permissions: { edit_users: [person.user_id] }, create_agents: true)
          }.not_to change(User, :count)
        end

        it 'does NOT create a new actor' do
          expect {
            described_class.call(resource: resource, permissions: { edit_users: [person.user_id] }, create_agents: true)
          }.not_to change(Actor, :count)
        end

        it 'does NOT add a new access control to the resource' do
          expect {
            described_class.call(resource: resource, permissions: { edit_users: [person.user_id] }, create_agents: true)
          }.not_to change(resource.edit_users, :count)
        end
      end

      context 'when the user already exists in the database' do
        let!(:user) { create(:user, access_id: person.user_id) }

        it 'does NOT create a new user from the permissions hash' do
          expect {
            described_class.call(resource: resource, permissions: { edit_users: [user.access_id] }, create_agents: true)
          }.not_to change(User, :count)
        end

        it 'does NOT create a new actor' do
          expect {
            described_class.call(resource: resource, permissions: { edit_users: [user.access_id] }, create_agents: true)
          }.not_to change(Actor, :count)
        end

        it 'does NOT add a new access control to the resource' do
          expect {
            described_class.call(resource: resource, permissions: { edit_users: [user.access_id] }, create_agents: true)
          }.not_to change(resource.edit_users, :count)
        end
      end
    end
  end

  context 'when we do NOT want to create new users' do
    context 'when the user does NOT exist in the database' do
      let(:access_id) { 'imnothere' }

      it 'does NOT create a new user from the permissions hash' do
        expect {
          described_class.call(resource: resource, permissions: { edit_users: [access_id] }, create_agents: false)
        }.not_to change(User, :count)
      end

      it 'does NOT create a new actor' do
        expect {
          described_class.call(resource: resource, permissions: { edit_users: [access_id] }, create_agents: false)
        }.not_to change(Actor, :count)
      end

      it 'does NOT add a new access control to the resource' do
        expect {
          described_class.call(resource: resource, permissions: { edit_users: [access_id] }, create_agents: false)
        }.not_to change(resource.edit_users, :count)
      end
    end

    context 'when the user already exists in the database' do
      let!(:user) { create(:user) }

      it 'does NOT create a new user from the permissions hash' do
        expect {
          described_class.call(resource: resource, permissions: { edit_users: [user.access_id] }, create_agents: false)
        }.not_to change(User, :count)
      end

      it 'does NOT create a new actor' do
        expect {
          described_class.call(resource: resource, permissions: { edit_users: [user.access_id] }, create_agents: false)
        }.not_to change(Actor, :count)
      end

      it 'adds a new access control using the existing user' do
        expect(resource.edit_users.map(&:uid)).not_to include(user.access_id)
        described_class.call(resource: resource, permissions: { edit_users: [user.access_id] }, create_agents: false)
        expect(resource.edit_users.map(&:uid)).to include(user.access_id)
      end
    end
  end
end
