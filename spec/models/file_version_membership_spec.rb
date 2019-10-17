# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileVersionMembership, type: :model do
  describe 'table' do
    it { is_expected.to have_db_column(:work_version_id) }
    it { is_expected.to have_db_column(:file_resource_id) }
    it { is_expected.to have_db_column(:title) }

    it { is_expected.to have_db_index(:work_version_id) }
    it { is_expected.to have_db_index(:file_resource_id) }
  end

  describe 'factories' do
    it { is_expected.to have_valid_factory(:file_version_membership) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:work_version) }
    it { is_expected.to belong_to(:file_resource) }
  end
end
