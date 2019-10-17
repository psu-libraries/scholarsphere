# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkCreation, type: :model do
  describe 'table' do
    it { is_expected.to have_db_column(:alias_id) }
    it { is_expected.to have_db_column(:work_id) }

    it { is_expected.to have_db_index(:alias_id) }
    it { is_expected.to have_db_index(:work_id) }
  end

  describe 'factories' do
    it { is_expected.to have_valid_factory(:work_creation) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:alias) }
    it { is_expected.to belong_to(:work) }
  end
end
