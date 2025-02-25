# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ThumbnailUpload do
  describe 'table' do
    it { is_expected.to have_db_column(:resource_type).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:resource_id).with_options(null: false) }
    it { is_expected.to have_db_column(:file_resource_id).with_options(null: false) }

    it { is_expected.to have_db_index(:file_resource_id).unique(true) }
    it { is_expected.to have_db_index([:resource_type, :resource_id]).unique(true) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:resource) }
    it { is_expected.to belong_to(:file_resource) }

    it { is_expected.to accept_nested_attributes_for(:file_resource) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:resource_id) }
    it { is_expected.to validate_presence_of(:resource_type) }
    it { is_expected.to validate_presence_of(:file_resource_id) }
  end
end
