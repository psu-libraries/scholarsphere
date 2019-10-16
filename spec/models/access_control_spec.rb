# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccessControl, type: :model do
  describe 'table' do
    it { is_expected.to have_db_column(:resource_type) }
    it { is_expected.to have_db_column(:resource_id) }
    it { is_expected.to have_db_column(:agent_type) }
    it { is_expected.to have_db_column(:agent_id) }
    it { is_expected.to have_db_column(:access_level) }
    it { is_expected.to have_db_index([:resource_type, :resource_id]) }
    it { is_expected.to have_db_index([:agent_type, :agent_id]) }
  end

  describe 'factories' do
    it { is_expected.to have_valid_factory(:access_control) }
    it { is_expected.to have_valid_factory(:access_control, :with_user) }
    it { is_expected.to have_valid_factory(:access_control, :with_group) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:agent) }
    it { is_expected.to belong_to(:resource) }
  end

  describe 'validations' do
    pending 'needed on access_level?'
  end
end
