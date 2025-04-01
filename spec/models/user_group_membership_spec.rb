# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserGroupMembership do
  describe 'table' do
    it { is_expected.to have_db_column(:user_id) }
    it { is_expected.to have_db_column(:group_id) }
  end

  describe 'factory' do
    it { is_expected.to have_valid_factory(:user_group_membership) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:group) }
  end
end
