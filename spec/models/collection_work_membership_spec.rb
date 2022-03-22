# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionWorkMembership, type: :model do
  describe 'table' do
    it { is_expected.to have_db_column(:collection_id) }
    it { is_expected.to have_db_column(:work_id) }
    it { is_expected.to have_db_column(:position).of_type(:integer) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime) }

    it { is_expected.to have_db_index(:collection_id) }
    it { is_expected.to have_db_index(:work_id) }
  end

  describe 'factory' do
    it { is_expected.to have_valid_factory(:collection_work_membership) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:collection) }
    it { is_expected.to belong_to(:work) }
  end

  describe 'validations' do
    let(:work) { create :work }
    let(:collection) { create :collection }

    it 'validates that a collection cannot contain the same work twice' do
      create :collection_work_membership, collection: collection, work: work

      second_one = build :collection_work_membership, collection: collection, work: work
      expect(second_one).not_to be_valid
    end
  end
end
