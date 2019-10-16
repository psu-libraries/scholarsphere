# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Work, type: :model do
  describe 'table' do
    it { is_expected.to have_db_column(:work_type).of_type(:string) }
    it { is_expected.to have_db_column(:depositor_id) }
    it { is_expected.to have_db_index(:depositor_id) }
  end

  describe 'factories' do
    it { is_expected.to have_valid_factory(:work) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:depositor).class_name('User').with_foreign_key(:depositor_id) }
    it { is_expected.to have_many(:work_creations) }
    it { is_expected.to have_many(:aliases).through(:work_creations) }
    it { is_expected.to have_many(:versions).class_name('WorkVersion').inverse_of('work') }

    it { is_expected.to accept_nested_attributes_for(:versions) }
  end

  describe 'validations' do
    it { is_expected.to validate_inclusion_of(:work_type).in_array(Work::Types.all) }
  end

  describe 'initialize' do
    it 'initializes a work version too' do
      expect(described_class.new.versions).not_to be_empty
    end

    it 'accepts initial work versions' do
      versions = [WorkVersion.new]
      new_work = described_class.new(versions: versions)
      expect(new_work.versions).to match_array(versions)
    end
  end
end
