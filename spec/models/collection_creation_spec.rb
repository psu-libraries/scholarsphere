# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectionCreation, type: :model do
  describe 'table' do
    it { is_expected.to have_db_column(:collection_id) }
    it { is_expected.to have_db_column(:actor_id) }
    it { is_expected.to have_db_column(:alias).of_type(:string) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime) }

    it { is_expected.to have_db_index(:collection_id) }
    it { is_expected.to have_db_index(:actor_id) }
  end

  describe 'factory' do
    it { is_expected.to have_valid_factory(:collection_creation) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:collection) }
    it { is_expected.to belong_to(:actor) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:alias) }
  end

  describe 'initialization' do
    let(:actor) { build :actor, default_alias: 'Actor Default Alias' }
    let(:collection) { build :collection }

    context 'when an alias is not provided' do
      subject(:creation) { described_class.new actor: actor, collection: collection }

      it 'initializes itself with the given Actor#default_alias' do
        creation.save!
        expect(creation.reload.alias).to eq 'Actor Default Alias'
      end
    end

    context 'when an alias is provided' do
      subject(:creation) { described_class.new alias: 'Provided Alias', actor: actor, collection: collection }

      it 'uses the provided alias' do
        creation.save!
        expect(creation.reload.alias).to eq 'Provided Alias'
      end
    end
  end
end
