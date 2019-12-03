# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'table' do
    it { is_expected.to have_db_column(:access_id).of_type(:string) }
    it { is_expected.to have_db_column(:email).of_type(:string) }
    it { is_expected.to have_db_column(:given_name).of_type(:string) }
    it { is_expected.to have_db_column(:surname).of_type(:string) }
    it { is_expected.to have_db_column(:provider).of_type(:string) }
    it { is_expected.to have_db_column(:uid).of_type(:string) }

    it { is_expected.to have_db_index(:email).unique }
  end

  describe 'factories' do
    it { is_expected.to have_valid_factory(:user) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:works) }
    it { is_expected.to have_many(:access_controls) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
  end

  describe 'Blacklight::User' do
    it { is_expected.to respond_to(:bookmarks) }
  end

  describe '.from_omniauth' do
    let(:auth_params) { build :psu_oauth_response,
                              given_name: 'Joe',
                              surname: 'Developer',
                              access_id: 'jd1'
    }

    context 'when the User record does not yet exist' do
      it 'creates a new User record' do
        expect { described_class.from_omniauth(auth_params) }
          .to change(described_class, :count)
          .by 1
      end

      it 'returns the newly created User' do
        new_user = described_class.from_omniauth(auth_params)
        expect(new_user).to be_persisted
        expect(new_user.access_id).to eq 'jd1'
        expect(new_user.given_name).to eq 'Joe'
        expect(new_user.surname).to eq 'Developer'
        expect(new_user.email).to eq 'jd1@psu.edu'
      end
    end

    context 'when the User record already exists' do
      let!(:existing_user) { create :user, provider: auth_params.provider, uid: auth_params.uid }

      it 'does NOT create a new record' do
        expect { described_class.from_omniauth(auth_params) }.not_to change(described_class, :count)
      end

      it 'does NOT update ANY attributes on the user record' do
        user_before = described_class.find(existing_user.id)
        described_class.from_omniauth(auth_params)
        user_after = described_class.find(existing_user.id)

        expect(user_after.access_id).to eq user_before.access_id
        expect(user_after.email).to eq user_before.email
        expect(user_after.given_name).to eq user_before.given_name
        expect(user_after.surname).to eq user_before.surname
      end

      it 'returns the User record' do
        expect(described_class.from_omniauth(auth_params)).to eq existing_user
      end
    end
  end

  describe '#name' do
    let(:user) { build_stubbed :user, given_name: 'Joe', surname: 'Developer' }

    it 'concatenates given_name and surname' do
      expect(user.name).to eq 'Joe Developer'
    end
  end
end
