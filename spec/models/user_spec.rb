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

    it { is_expected.to have_db_index(:email).unique }
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

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
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
                              groups: [
                                'cn=admin,dc=psu,dc=edu',
                                'cn=reporter,dc=psu,dc=edu',
                                'cn=totally invalid with spaces,dc=psu,dc=edu'
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

          expect(new_user.groups.length).to eq 4
          expect(new_user.groups.map(&:name)).to contain_exactly(
            'admin',
            'reporter',
            Group::AUTHORIZED_AGENT_NAME,
            Group::PUBLIC_AGENT_NAME
          )
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

          expect(new_user.groups.length).to eq 4
        end
      end
    end

    context 'when the User record already exists' do
      let!(:existing_user) { create :user, provider: auth_params.provider, uid: auth_params.uid }

      it 'does NOT create a new record' do
        expect { described_class.from_omniauth(auth_params) }.not_to change(described_class, :count)
      end

      it 'overwrites all user attributes, except access_id' do
        user_before = described_class.find(existing_user.id)
        described_class.from_omniauth(auth_params)
        user_after = described_class.find(existing_user.id)

        # OAuth does NOT overwrite these attributes:
        expect(user_after.access_id).to eq user_before.access_id

        # OAuth DOES overwrite these attributes:
        expect(user_after.email).not_to eq user_before.email
      end

      it 'DOES update the group membership' do
        existing_user.groups.create!(name: 'MY OLD GROUP THAT SHOULD GO AWAY')
        described_class.from_omniauth(auth_params)

        expect(existing_user.reload.groups.map(&:name)).to contain_exactly(
          'admin',
          'reporter',
          Group::AUTHORIZED_AGENT_NAME,
          Group::PUBLIC_AGENT_NAME
        )
      end

      it 'returns the User record' do
        expect(described_class.from_omniauth(auth_params)).to eq existing_user
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

  describe '#admin?' do
    let(:user) { build_stubbed :user }
    let(:admin_user) { create(:user, :admin) }

    it 'is false when user is not an admin' do
      expect(user.admin?).to be false
    end

    it 'is true when user is an admin' do
      expect(admin_user.admin?).to be true
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
    it { is_expected.to delegate_method(:name).to(:actor).as(:default_alias) }
  end
end
