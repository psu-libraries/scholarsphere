# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Group, type: :model do
  describe 'table' do
    it { is_expected.to have_db_column(:name) }
    it { is_expected.to have_db_index(:name) }
  end

  describe 'factory' do
    it { is_expected.to have_valid_factory(:group) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:access_controls) }
    it { is_expected.to have_many(:user_group_memberships) }
    it { is_expected.to have_many(:users).through(:user_group_memberships) }
  end
end
