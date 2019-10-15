# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'table' do
    it { is_expected.to have_db_column(:access_id).of_type(:string) }
    it { is_expected.to have_db_column(:email).of_type(:string) }
    it { is_expected.to have_db_column(:name).of_type(:string) }
    it { is_expected.to have_db_column(:provider).of_type(:string) }
    it { is_expected.to have_db_column(:uid).of_type(:string) }

    it { is_expected.to have_db_index(:email).unique }
  end

  describe 'factory' do
    it 'has a valid factory' do
      factory = build :user
      expect(factory).to be_valid
      expect { factory.save! }.not_to raise_error
    end
  end

  describe 'associations' do
    it { is_expected.to have_many(:works) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email) }
  end
end
