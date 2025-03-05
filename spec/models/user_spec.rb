# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  subject(:user) { build :user }

  describe 'table' do
    subject { described_class.new }

    it { is_expected.to have_db_column(:access_id).of_type(:string) }
    it { is_expected.to have_db_column(:email).of_type(:string) }
    it { is_expected.to have_db_column(:provider).of_type(:string) }
    it { is_expected.to have_db_column(:uid).of_type(:string) }
    it { is_expected.to have_db_column(:actor_id) }
    it { is_expected.to have_db_column(:admin_enabled).of_type(:boolean) }

    it { is_expected.to have_db_index(:access_id).unique }
    it { is_expected.to have_db_index(:actor_id) }
  end

  describe 'factories' do
    it { is_expected.to have_valid_factory(:user) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:actor) }
    it { is_expected.to have_many(:access_controls) }
    it { is_expected.to have_many(:user_group_memberships) }
    it { is_expected.to have_many(:groups).through(:user_group_memberships) }
  end

  describe 'validations' do
    subject { create :user } # validate_uniqueness_of really wants this, not sure why

    it { is_expected.to validate_presence_of(:access_id) }
    it { is_expected.to validate_uniqueness_of(:access_id).case_insensitive }
  end

  describe 'Blacklight::User' do
    it { is_expected.to respond_to(:bookmarks) }
  end

  describe '.guest' do
    subject { described_class.guest }

    it { is_expected.to be_guest }
    its(:groups) { is_expected.to contain_exactly(Group.public_agent) }
    it { is_expected.to be_readonly }
  end

  describe '.from_omniauth' do
    let(:auth_params) { build :psu_oauth_response,
                              given_name: 'Joe',
                              surname: 'Developer',
                              access_id: 'jd1',
                              info_groups: [
                                'umg-admin',
                                'umg-reporter',
                                'Invalid With Spaces',
                                'umg-With Spaces',
                                Group::PSU_AFFILIATED_AGENT_NAME
                              ]
    }

    context 'when the User record does not yet exist' do
      context 'when an Actor record with the same PSU ID does not exist' do
        it 'creates a new User' do
          expect { described_class.from_omniauth(auth_params) }
            .to change(described_class, :count).by(1)
        end

        it 'creates a new Actor record' do
          expect { described_class.from_omniauth(auth_params) }
            .to change(Actor, :count).by(1)
        end

        it 'returns the newly created User, associated with the new Actor' do
          new_user = described_class.from_omniauth(auth_params)
          expect(new_user).to be_persisted
          expect(new_user.access_id).to eq 'jd1'
          expect(new_user.email).to eq 'jd1@psu.edu'

          new_user.actor.tap do |actor|
            expect(actor.psu_id).to eq 'jd1'
            expect(actor.email).to eq 'jd1@psu.edu'
            expect(actor.given_name).to eq 'Joe'
            expect(actor.surname).to eq 'Developer'
          end

          expect(new_user.groups.length).to eq 5
          expect(new_user.groups.map(&:name)).to contain_exactly(
            'umg-admin',
            'umg-reporter',
            Group::AUTHORIZED_AGENT_NAME,
            Group::PUBLIC_AGENT_NAME,
            Group::PSU_AFFILIATED_AGENT_NAME
          )
        end

        context 'when Group::PSU_AFFILIATED_AGENT_NAME is not present in auth_params groups' do
          before do
            auth_params.info.groups.delete(Group::PSU_AFFILIATED_AGENT_NAME)
          end

          it 'removes Group::AUTHORIZED_AGENT_NAME' do
            new_user = described_class.from_omniauth(auth_params)
            expect(new_user.groups.length).to eq 3
            expect(new_user.groups.map(&:name)).to contain_exactly(
              'umg-admin',
              'umg-reporter',
              Group::PUBLIC_AGENT_NAME
            )
          end
        end
      end

      context 'when an Actor record with the same PSU ID exists' do
        let!(:actor) { create :actor, psu_id: 'jd1' }

        it 'creates a new User record' do
          expect { described_class.from_omniauth(auth_params) }
            .to change(described_class, :count).by(1)
        end

        it 'does NOT create a new Actor record' do
          expect { described_class.from_omniauth(auth_params) }
            .not_to change(Actor, :count)
        end

        it 'returns the newly created User, associated with the existing Actor' do
          new_user = described_class.from_omniauth(auth_params)
          expect(new_user).to be_persisted
          expect(new_user.access_id).to eq 'jd1'

          expect(new_user.actor).to eq actor

          expect(new_user.groups.length).to eq 5
        end

        context 'when Group::PSU_AFFILIATED_AGENT_NAME is not present in auth_params groups' do
          before do
            auth_params.info.groups.delete(Group::PSU_AFFILIATED_AGENT_NAME)
          end

          it 'removes Group::AUTHORIZED_AGENT_NAME' do
            new_user = described_class.from_omniauth(auth_params)
            expect(new_user.groups.length).to eq 3
            expect(new_user.groups.map(&:name)).to contain_exactly(
              'umg-admin',
              'umg-reporter',
              Group::PUBLIC_AGENT_NAME
            )
          end
        end
      end
    end

    context 'when the User record already exists' do
      let!(:existing_user) { create :user, provider: auth_params.provider, uid: auth_params.uid }

      before do
        # Manipulate the Actor record to test it being updated
        existing_user.actor.surname = 'Different than OAuth'
        existing_user.actor.email = ''
        existing_user.actor.save!(validate: false)
      end

      it 'does NOT create a new record' do
        expect { described_class.from_omniauth(auth_params) }.not_to change(described_class, :count)
      end

      it 'overwrites all user attributes, except access_id' do
        user_before = described_class.find(existing_user.id)
        actor_before = user_before.actor
        described_class.from_omniauth(auth_params)
        user_after = described_class.find(existing_user.id)
        actor_after = user_after.actor

        # OAuth does NOT overwrite these attributes:
        expect(user_after.access_id).to eq user_before.access_id

        # OAuth DOES overwrite these attributes:
        expect(user_after.email).not_to eq user_before.email

        # OAuth will overwrite these attributes if and only if they are blank
        expect(actor_after.surname).to eq actor_before.surname
        expect(actor_after.email).not_to eq actor_before.email
      end

      it 'DOES update the group membership' do
        existing_user.groups.create!(name: 'MY OLD GROUP THAT SHOULD GO AWAY')
        described_class.from_omniauth(auth_params)

        expect(existing_user.reload.groups.map(&:name)).to contain_exactly(
          'umg-admin',
          'umg-reporter',
          Group::AUTHORIZED_AGENT_NAME,
          Group::PUBLIC_AGENT_NAME,
          Group::PSU_AFFILIATED_AGENT_NAME
        )
      end

      it 'returns the User record' do
        expect(described_class.from_omniauth(auth_params)).to eq existing_user
      end

      context 'when Group::PSU_AFFILIATED_AGENT_NAME is not present in auth_params groups' do
        before do
          auth_params.info.groups.delete(Group::PSU_AFFILIATED_AGENT_NAME)
        end

        it 'removes Group::AUTHORIZED_AGENT_NAME' do
          new_user = described_class.from_omniauth(auth_params)
          expect(new_user.groups.length).to eq 3
          expect(new_user.groups.map(&:name)).to contain_exactly(
            'umg-admin',
            'umg-reporter',
            Group::PUBLIC_AGENT_NAME
          )
        end
      end
    end

    context 'when OAuth response contains minimal user info' do
      # This wouldn't pass validation in the web ui, but will pass here
      let(:auth_params) { build :psu_oauth_response,
                                given_name: nil,
                                surname: nil,
                                access_id: 'jd1',
                                groups: []
      }

      it 'still creates the Author and User' do
        expect { described_class.from_omniauth(auth_params) }
          .to change(described_class, :count).by(1)
          .and change(Actor, :count).by(1)
      end
    end

    context 'when a validation error occurs' do
      before do
        auth_params.uid = nil
        to_struct = Struct.new(:orc_id)
        user_meta = to_struct.new(orc_id: nil)
        allow(PsuIdentity::DirectoryService::Client)
          .to receive(:new)
          .and_return user_meta
      end

      it do
        expect { described_class.from_omniauth(auth_params) }
          .to raise_error(described_class::OAuthError)
          .with_message(/Validation/)
      end

      it 'rolls back any database changes made' do
        expect {
          begin
            described_class.from_omniauth(auth_params)
          rescue described_class::OAuthError
          end
        }.to change(described_class, :count).by(0)
          .and change(Actor, :count).by(0)
          .and change(Group, :count).by(0)
      end
    end

    context 'when an unknown error occurs' do
      before do
        allow(LdapGroupCleaner).to receive(:call).and_raise(RuntimeError, 'ack!')
      end

      it do
        pending('djb44 - LdapGroupCleaner I dont think is needed')
        expect { described_class.from_omniauth(auth_params) }
          .to raise_error(described_class::OAuthError)
          .with_message(/ack/)
      end
    end
  end

  describe '#assign_groups' do
    context 'when psu_affiliated_agent group is one of the psu_groups' do
      let(:psu_groups) { [Group.new(name: 'abc-group'),
                          Group.new(name: 'def-group'),
                          Group.psu_affiliated_agent] }

      it 'assigns default groups and psu_groups' do
        user = described_class.new
        user.assign_groups(psu_groups)
        expect(user.groups).to contain_exactly(Group.public_agent, Group.authorized_agent,
                                               Group.psu_affiliated_agent, psu_groups[0], psu_groups[1])
      end
    end

    context 'when psu_affiliated_agent group is not one of the psu_groups' do
      let(:psu_groups) { [Group.new(name: 'abc-group'),
                          Group.new(name: 'def-group')] }

      it 'assigns public_agent group and psu_groups (not authorized_agent group)' do
        user = described_class.new
        user.assign_groups(psu_groups)
        expect(user.groups).to contain_exactly(Group.public_agent, psu_groups[0], psu_groups[1])
      end
    end
  end

  describe '#works' do
    let(:user) { create :user }
    let(:user_actor) { user.actor }

    let(:different_user) { create :user }
    let(:different_actor) { different_user.actor }

    let!(:deposited_work) { create :work, depositor: user_actor }
    let!(:proxied_work) { create :work, depositor: different_actor, proxy_depositor: user_actor }

    before do
      create :work, depositor: different_actor
    end

    it "returns a scope of works where the User's Actor is either the depositor or proxy" do
      expect(user.works).to contain_exactly(deposited_work, proxied_work)
    end
  end

  describe '#collections' do
    let(:user) { create :user }
    let(:user_actor) { user.actor }

    let(:different_user) { create :user }
    let(:different_actor) { different_user.actor }

    let!(:deposited_collection) { create :collection, depositor: user_actor }

    before do
      create :collection, depositor: different_actor
    end

    it "returns a scope of works where the User's Actor is either the depositor or proxy" do
      expect(user.collections).to contain_exactly(deposited_collection)
    end
  end

  describe '#admin?' do
    subject { user }

    context 'when the user is not an admin' do
      let(:user) { build_stubbed :user }

      it { is_expected.not_to be_admin }
    end

    context 'when the user is an admin and enabled' do
      let(:user) { build(:user, :admin, admin_enabled: true) }

      it { is_expected.to be_admin }
    end

    context 'when the user is an admin but not enabled' do
      let(:user) { build(:user, :admin, admin_enabled: false) }

      it { is_expected.not_to be_admin }
    end
  end

  describe '#admin_available?' do
    subject { user }

    context 'when the user is not an admin' do
      let(:user) { build_stubbed :user }

      it { is_expected.not_to be_admin_available }
    end

    context 'when the user is an admin' do
      let(:user) { build(:user, :admin) }

      it { is_expected.to be_admin_available }
    end
  end

  describe '#guest?' do
    context 'with a new user' do
      subject { described_class.new }

      it { is_expected.not_to be_guest }
    end

    context 'with an existing user' do
      subject { build(:user) }

      it { is_expected.not_to be_guest }
    end

    context 'with a guest user' do
      subject { build(:user, guest: true) }

      it { is_expected.to be_guest }
    end
  end

  describe '#name' do
    it { is_expected.to delegate_method(:name).to(:actor).as(:display_name) }
  end
end
