# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Creator, type: :model do
  describe 'table' do
    it { is_expected.to have_db_column(:given_name).of_type(:string) }
    it { is_expected.to have_db_column(:surname).of_type(:string) }
    it { is_expected.to have_db_column(:email).of_type(:string) }
    it { is_expected.to have_db_column(:psu_id).of_type(:string) }
    it { is_expected.to have_db_column(:orcid).of_type(:string) }

    pending 'Should creators have any indexes on it?'
  end

  describe 'factories' do
    it { is_expected.to have_valid_factory(:creator) }
  end

  describe 'associations' do
    xit { is_expected.to have_many(:aliases) }
  end

  describe 'validations' do
    pending 'What validations does Creator need?'
  end
end
