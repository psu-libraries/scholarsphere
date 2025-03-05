# frozen_string_literal: true

require 'rails_helper'

# @note This is the main service that migrates existing Scholarsphere 3 collections. It shares a lot simlarities with
# PublishNewCollection

RSpec.describe CreateNewCollection do
  let(:user) { build(:user) }
  let(:collection) { build(:collection, :with_complete_metadata) }
  let(:work) { create(:work) }

  let(:depositor) do
    HashWithIndifferentAccess.new(
      email: user.email,
      given_name: user.actor.given_name,
      surname: user.actor.surname,
      psu_id: user.actor.psu_id
    )
  end

  context 'when the depositor is the same as the creator' do
    let(:new_collection) do
      described_class.call(
        metadata: HashWithIndifferentAccess.new(collection.metadata.merge(
                                                  work_ids: [work.id],
                                                  creators_attributes: [
                                                    {
                                                      display_name: user.name,
                                                      position: 1,
                                                      actor_attributes: {
                                                        email: user.email,
                                                        given_name: user.actor.given_name,
                                                        surname: user.actor.surname,
                                                        psu_id: user.actor.psu_id
                                                      }
                                                    }
                                                  ]
                                                )),
        depositor: depositor
      )
    end

    it 'creates an open access collection with complete metadata and one member work' do
      expect(new_collection).to be_open_access
      expect(new_collection.metadata).to eq(collection.metadata)
      expect(new_collection.works).to contain_exactly(work)
    end

    it 'creates a new Actor record for the depositor' do
      expect { new_collection }.to change {
        Actor.where(psu_id: user.actor.psu_id).count
      }.from(0).to(1)
    end

    it 'does NOT create a User record for the depositor' do
      expect { new_collection }.not_to(
        change { User.where(access_id: user.actor.psu_id).empty? }
      )
    end
  end

  context 'when the actor already exists in the system' do
    let(:new_collection) do
      described_class.call(
        metadata: HashWithIndifferentAccess.new(collection.metadata.merge(
                                                  work_ids: [work.id],
                                                  creators_attributes: [
                                                    {
                                                      display_name: user.name,
                                                      position: 1,
                                                      actor_attributes: {
                                                        email: user.email,
                                                        given_name: user.actor.given_name,
                                                        surname: user.actor.surname,
                                                        psu_id: user.actor.psu_id
                                                      }
                                                    }
                                                  ]
                                                )),
        depositor: depositor
      )
    end

    before { user.save }

    it 'creates a new collection' do
      expect { new_collection }.to change(Collection, :count).by(1)
    end

    it 'does NOT create an Actor record for the depositor' do
      expect { new_collection }.not_to(
        change { Actor.where(psu_id: user.access_id).empty? }
      )
    end

    it 'does NOT create a User record for the depositor' do
      expect { new_collection }.not_to(
        change { User.where(access_id: user.actor.psu_id).empty? }
      )
    end
  end

  context 'when specifying additional permissions on the collection' do
    let(:edit_user) { build(:person) }
    let(:edit_group) { build(:group) }
    let(:mock_client) { instance_spy('PsuIdentity::SearchService::Client') }
    let(:new_collection) do
      described_class.call(
        metadata: HashWithIndifferentAccess.new(collection.metadata.merge(
                                                  work_ids: [work.id],
                                                  creators_attributes: [
                                                    {
                                                      display_name: user.name,
                                                      position: 1,
                                                      actor_attributes: {
                                                        email: user.email,
                                                        given_name: user.actor.given_name,
                                                        surname: user.actor.surname,
                                                        psu_id: user.actor.psu_id
                                                      }
                                                    }
                                                  ]
                                                )),
        depositor: depositor,
        permissions: {
          edit_users: [edit_user.user_id],
          edit_groups: [edit_group.name]
        }
      )
    end

    # @note Save specific groups and users prior to the test so our expectations reflect the changes that the service
    # is making, as opposed to the additional changes due to an empty database.
    before do
      allow(PsuIdentity::SearchService::Client).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:userid).with(edit_user.user_id).and_return(edit_user)
      user.save
      Group.public_agent
      Group.authorized_agent
      Group.psu_affiliated_agent
    end

    it 'creates a new Group record for the edit group in the permissions parameter' do
      expect { new_collection }.to change(Group, :count).from(3).to(4)
    end

    it 'creates a new User record for the edit user in the permissions parameter' do
      expect { new_collection }.to change {
        User.where(access_id: edit_user.user_id).count
      }.from(0).to(1)
    end

    it 'creates a new Actor record for the edit user in the permissions parameter' do
      expect { new_collection }.to change {
        Actor.where(psu_id: edit_user.user_id).count
      }.from(0).to(1)
    end

    it 'adds two access controls for the additional permissions, and two more for work and collection visibility' do
      expect { new_collection }.to change(AccessControl, :count).from(0).to(10)
    end
  end

  context 'without a required title' do
    let(:new_collection) do
      described_class.call(metadata: { description: Faker::Lorem.paragraph }, depositor: depositor)
    end

    it 'does NOT save the collection' do
      expect { new_collection }.not_to change(Work, :count)
    end

    it 'does NOT create an Actor for the depositor' do
      pending('Need to implement transactions to rollback any changes to the database when works fail to save')
      expect { new_collection }.not_to change(Actor, :count)
    end

    it 'does NOT create a User record for the depositor' do
      expect { new_collection }.not_to change(User, :count)
    end

    it 'returns the collection with errors' do
      expect(new_collection.errors.full_messages).to contain_exactly("Title can't be blank")
    end
  end

  context 'with custom deposit dates' do
    let(:new_collection) do
      described_class.call(
        metadata: HashWithIndifferentAccess.new(collection.metadata.merge(
                                                  work_ids: [work.id],
                                                  creators_attributes: [
                                                    {
                                                      display_name: user.name,
                                                      position: 1,
                                                      actor_attributes: {
                                                        email: user.email,
                                                        given_name: user.actor.given_name,
                                                        surname: user.actor.surname,
                                                        psu_id: user.actor.psu_id
                                                      }
                                                    }
                                                  ],
                                                  deposited_at: '2017-05-11T16:20:54Z'
                                                )),
        depositor: depositor
      )
    end

    it 'creates a new collection with the specified deposit date' do
      expect(new_collection.deposited_at.strftime('%Y-%m-%d')).to eq('2017-05-11')
      expect(new_collection.deposited_at).to be_a(ActiveSupport::TimeWithZone)
      expect(new_collection.deposited_at.zone).to eq('EDT')
    end
  end
end
