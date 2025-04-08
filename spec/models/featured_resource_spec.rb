# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FeaturedResource do
  describe 'table' do
    it { is_expected.to have_db_column(:resource_uuid).of_type(:uuid) }
    it { is_expected.to have_db_column(:resource_type) }
    it { is_expected.to have_db_column(:resource_id) }
    it { is_expected.to have_db_index([:resource_type, :resource_id]) }
    it { is_expected.to have_db_index([:resource_uuid, :resource_type, :resource_id]) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:resource_uuid) }
  end

  describe 'factories' do
    it { is_expected.to have_valid_factory(:featured_resource) }
  end
end
