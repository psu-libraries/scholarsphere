# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Alias, type: :model do
  describe 'table' do
    it { is_expected.to have_db_column(:creator_id) }
    it { is_expected.to have_db_column(:display_name).of_type(:string) }

    it { is_expected.to have_db_index(:creator_id) }
  end

  describe 'factories' do
    it { is_expected.to have_valid_factory(:alias) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:creator) }
    it { is_expected.to have_many(:work_creations) }
    it { is_expected.to have_many(:works).through(:work_creations) }
  end
end
