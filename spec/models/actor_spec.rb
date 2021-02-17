# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Actor, type: :model do
  describe 'table' do
    it { is_expected.to have_db_column(:given_name).of_type(:string) }
    it { is_expected.to have_db_column(:surname).of_type(:string) }
    it { is_expected.to have_db_column(:email).of_type(:string) }
    it { is_expected.to have_db_column(:psu_id).of_type(:string) }
    it { is_expected.to have_db_column(:orcid).of_type(:string) }
    it { is_expected.to have_db_column(:default_alias).of_type(:string) }

    it { is_expected.to have_db_index(:psu_id) }
  end

  describe 'factories' do
    it { is_expected.to have_valid_factory(:actor) }
  end

  describe 'associations' do
    it { is_expected.to have_one(:user) }
    it { is_expected.to have_many(:authorships) }
    it { is_expected.to have_many(:created_work_versions) }
    it { is_expected.to have_many(:created_works) }
    it { is_expected.to have_many(:created_collections) }
    it { is_expected.to have_many(:collection_creations) }
    it { is_expected.to have_many(:deposited_works).class_name('Work').inverse_of(:depositor) }
    it { is_expected.to have_many(:proxy_deposited_works).class_name('Work').inverse_of(:proxy_depositor) }
    it { is_expected.to have_many(:deposited_collections).class_name('Collection').inverse_of(:depositor) }
  end

  describe 'validations' do
    context 'when given no validation context' do
      it { is_expected.to validate_presence_of(:surname) }
      it { is_expected.not_to validate_presence_of(:psu_id) }
      it { is_expected.to validate_uniqueness_of(:psu_id).case_insensitive }
      it { is_expected.not_to validate_presence_of(:orcid) }
      it { is_expected.to validate_uniqueness_of(:orcid).case_insensitive }
    end

    context 'when given the from_omniauth context' do
      it { is_expected.not_to validate_presence_of(:surname).on(:from_omniauth) }
      it { is_expected.to validate_presence_of(:psu_id).on(:from_omniauth) }
      it { is_expected.to validate_uniqueness_of(:psu_id).on(:from_omniauth).case_insensitive }
      it { is_expected.not_to validate_presence_of(:orcid).on(:from_omniauth) }
      it { is_expected.to validate_uniqueness_of(:orcid).on(:from_omniauth).case_insensitive }
    end

    context 'when given the from_user context' do
      it { is_expected.to validate_presence_of(:surname).on(:from_user) }
      it { is_expected.not_to validate_presence_of(:psu_id).on(:from_user) }
      it { is_expected.to validate_uniqueness_of(:psu_id).on(:from_user).case_insensitive }
      it { is_expected.to validate_presence_of(:orcid).on(:from_user) }
      it { is_expected.to validate_uniqueness_of(:orcid).on(:from_user).case_insensitive }
    end
  end

  describe 'after_save' do
    let(:actor) { create :actor }

    before { allow(actor).to receive(:update_index_async) }

    context 'when the default_alias has changed' do
      it 'triggers update_index_async' do
        actor.default_alias = "I'm a changed person"
        actor.save
        expect(actor).to have_received(:update_index_async)
      end
    end

    context 'when the default_alias has NOT changed' do
      it 'does not trigger update_index_async' do
        actor.save
        expect(actor).not_to have_received(:update_index_async)
      end
    end
  end

  describe 'after destroy' do
    let(:actor) { create :actor }

    before { allow(actor).to receive(:update_index_async) }

    it 'reindexes its former works and collections' do
      actor.destroy
      expect(actor).to have_received(:update_index_async)
    end
  end

  describe '#default_alias' do
    let(:actor) { build :actor, given_name: 'Pat', surname: 'Researcher' }

    context 'when nil' do
      before { actor.default_alias = nil }

      it 'defaults to concatenated given and surname' do
        expect(actor.default_alias).to eq 'Pat Researcher'
      end
    end

    context 'when set' do
      before { actor.default_alias = 'Dr. Pat Q. Researcher PhD MD MLIS' }

      it 'returns the saved value' do
        expect(actor.default_alias).to eq 'Dr. Pat Q. Researcher PhD MD MLIS'
      end
    end
  end

  describe '#update_index_async' do
    let(:actor) { described_class.new }

    before { allow(SolrIndexingJob).to receive(:perform_later) }

    it 'provides itself to SolrIndexingJob.perform_later' do
      actor.update_index_async
      expect(SolrIndexingJob).to have_received(:perform_later).with(actor)
    end
  end

  describe '#update_index' do
    let(:actor) { create :actor }

    it 'updates all Works and Collections that the actor has created' do
      allow(Work).to receive(:reindex_all)
      allow(Collection).to receive(:reindex_all)

      actor.update_index

      expect(Work).to have_received(:reindex_all).with(relation: actor.created_works)
      expect(Collection).to have_received(:reindex_all).with(relation: actor.created_collections)
    end
  end

  describe 'singlevalued fields' do
    it_behaves_like 'a singlevalued field', :surname
    it_behaves_like 'a singlevalued field', :given_name
    it_behaves_like 'a singlevalued field', :email
    it_behaves_like 'a singlevalued field', :psu_id
    it_behaves_like 'a singlevalued field', :orcid
  end

  describe '#orcid' do
    context 'when set to valid value' do
      subject { described_class.new(surname: 'Valid Orcid', orcid: FactoryBotHelpers.generate_orcid) }

      it { is_expected.to be_valid }
    end

    context 'when set to an invalid value' do
      subject { actor.errors.full_messages }

      let(:actor) { described_class.new(orcid: Faker::Number.leading_zero_number(digits: 15)) }

      before { actor.validate }

      it { is_expected.to include('ORCiD must be valid') }
    end
  end
end
