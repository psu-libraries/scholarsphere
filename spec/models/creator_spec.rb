# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Creator, type: :model do
  describe 'table' do
    it { is_expected.to have_db_column(:given_name).of_type(:string) }
    it { is_expected.to have_db_column(:surname).of_type(:string) }
    it { is_expected.to have_db_column(:email).of_type(:string) }
    it { is_expected.to have_db_column(:psu_id).of_type(:string) }
    it { is_expected.to have_db_column(:orcid).of_type(:string) }
    it { is_expected.to have_db_column(:default_alias).of_type(:string) }

    it { is_expected.to have_db_index(:psu_id) }
  end

  describe 'factories' do
    it { is_expected.to have_valid_factory(:creator) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:work_version_creations) }
    it { is_expected.to have_many(:work_versions).through(:work_version_creations) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:email) }
  end

  describe '.find_or_create_by_user' do
    let(:user) { create :user }

    it 'creates a Creator from a User if none exists' do
      creator = described_class.find_or_create_by_user(user)

      expect(creator).to be_persisted
      expect(creator.psu_id).to eq user.access_id
      expect(creator.email).to eq user.email
      expect(creator.given_name).to eq user.given_name
      expect(creator.surname).to eq user.surname
    end

    it 'returns a matching Creator if one exists' do
      described_class.find_or_create_by_user(user)

      expect {
        @existing_creator = described_class.find_or_create_by_user(user)
      }.not_to change(described_class, :count)

      expect(@existing_creator.psu_id).to eq user.access_id
    end
  end

  describe '#default_alias' do
    let(:creator) { build :creator, given_name: 'Pat', surname: 'Researcher' }

    context 'when nil' do
      before { creator.default_alias = nil }

      it 'defaults to concatenated given and surname' do
        expect(creator.default_alias).to eq 'Pat Researcher'
      end
    end

    context 'when set' do
      before { creator.default_alias = 'Dr. Pat Q. Researcher PhD MD MLIS' }

      it 'returns the saved value' do
        expect(creator.default_alias).to eq 'Dr. Pat Q. Researcher PhD MD MLIS'
      end
    end
  end
end
