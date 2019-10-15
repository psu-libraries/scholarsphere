# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Work, type: :model do
  describe 'table' do
    it { is_expected.to have_db_column(:work_type).of_type(:string) }
    it { is_expected.to have_db_column(:depositor_id) }
    it { is_expected.to have_db_index(:depositor_id) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      factory = build :work
      expect(factory).to be_valid
      expect { factory.save! }.not_to raise_error
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:depositor).class_name('User').with_foreign_key(:depositor_id) }
  end

  describe 'validations' do
    it { is_expected.to validate_inclusion_of(:work_type).in_array(Work::Types.all) }
  end
end
