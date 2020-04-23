# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Collection, type: :model do
  describe 'table' do
    it { is_expected.to have_db_column(:depositor_id) }
    it { is_expected.to have_db_column(:metadata).of_type(:jsonb) }
    it { is_expected.to have_db_column(:uuid).of_type(:uuid) }
    it { is_expected.to have_db_column(:doi).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:title).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:subtitle).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:keyword).of_type(:string).is_array.with_default([]) }
    it { is_expected.to have_jsonb_accessor(:description).of_type(:string).is_array.with_default([]) }
    it { is_expected.to have_jsonb_accessor(:resource_type).of_type(:string).is_array.with_default([]) }
    it { is_expected.to have_jsonb_accessor(:contributor).of_type(:string).is_array.with_default([]) }
    it { is_expected.to have_jsonb_accessor(:publisher).of_type(:string).is_array.with_default([]) }
    it { is_expected.to have_jsonb_accessor(:published_date).of_type(:string).is_array.with_default([]) }
    it { is_expected.to have_jsonb_accessor(:subject).of_type(:string).is_array.with_default([]) }
    it { is_expected.to have_jsonb_accessor(:language).of_type(:string).is_array.with_default([]) }
    it { is_expected.to have_jsonb_accessor(:identifier).of_type(:string).is_array.with_default([]) }
    it { is_expected.to have_jsonb_accessor(:based_near).of_type(:string).is_array.with_default([]) }
    it { is_expected.to have_jsonb_accessor(:related_url).of_type(:string).is_array.with_default([]) }
    it { is_expected.to have_jsonb_accessor(:source).of_type(:string).is_array.with_default([]) }

    it { is_expected.to have_db_index(:depositor_id) }
  end

  describe 'factory' do
    it { is_expected.to have_valid_factory(:collection) }
    it { is_expected.to have_valid_factory(:collection, :with_complete_metadata) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:depositor).class_name('Actor').with_foreign_key(:depositor_id).inverse_of(:deposited_works) }
    it { is_expected.to have_many(:legacy_identifiers) }
    it { is_expected.to have_many(:collection_work_memberships) }
    it { is_expected.to have_many(:works).through(:collection_work_memberships) }
    it { is_expected.to have_many(:creator_aliases) }
    it { is_expected.to have_many(:creators).through(:creator_aliases) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
  end

  describe '#build_creator_alias' do
    let(:actor) { build_stubbed :actor }
    let(:collection) { build_stubbed :collection }

    it 'builds a creator_alias for the given Actor but does not persist it' do
      expect {
        collection.build_creator_alias(actor: actor)
      }.to change {
        collection.creator_aliases.length
      }.by(1)

      collection.creator_aliases.first.tap do |creator_alias|
        expect(creator_alias).not_to be_persisted
        expect(creator_alias.actor).to eq actor
        expect(creator_alias.alias).to eq actor.default_alias
      end
    end

    it 'is idempotent' do
      expect {
        2.times { collection.build_creator_alias(actor: actor) }
      }.to change {
        collection.creator_aliases.length
      }.by(1)
    end
  end
end
