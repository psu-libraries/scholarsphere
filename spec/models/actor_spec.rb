# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Actor do
  describe 'table' do
    it { is_expected.to have_db_column(:given_name).of_type(:string) }
    it { is_expected.to have_db_column(:surname).of_type(:string) }
    it { is_expected.to have_db_column(:email).of_type(:string) }
    it { is_expected.to have_db_column(:psu_id).of_type(:string) }
    it { is_expected.to have_db_column(:orcid).of_type(:string) }
    it { is_expected.to have_db_column(:display_name).of_type(:string) }

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
    it { is_expected.to have_many(:deposited_works).class_name('Work').inverse_of(:depositor) }
    it { is_expected.to have_many(:proxy_deposited_works).class_name('Work').inverse_of(:proxy_depositor) }
    it { is_expected.to have_many(:deposited_collections).class_name('Collection').inverse_of(:depositor) }
  end

  describe 'validations' do
    context 'when given no validation context' do
      it { is_expected.to validate_presence_of(:surname) }
      it { is_expected.to validate_presence_of(:psu_id) }
      it { is_expected.to validate_uniqueness_of(:psu_id).case_insensitive }
      it { is_expected.to validate_presence_of(:orcid) }
      it { is_expected.to validate_uniqueness_of(:orcid).case_insensitive }
    end

    context 'when given the from_omniauth context' do
      it { is_expected.not_to validate_presence_of(:surname).on(:from_omniauth) }
    end

    context 'when neither orcid nor psu_id are present' do
      subject { build(:actor, orcid: nil, psu_id: nil) }

      it { is_expected.not_to be_valid }
    end
  end

  describe 'after_commit' do
    let(:actor) { create(:actor) }

    before { allow(actor).to receive(:update_index_async) }

    context 'when the display_name has changed' do
      it 'triggers update_index_async' do
        actor.display_name = "I'm a changed person"
        actor.save
        expect(actor).to have_received(:update_index_async)
      end
    end

    context 'when the display_name has NOT changed' do
      it 'does not trigger update_index_async' do
        actor.save
        expect(actor).not_to have_received(:update_index_async)
      end
    end
  end

  describe 'after destroy' do
    let(:actor) { create(:actor) }

    before { allow(actor).to receive(:update_index_async) }

    it 'reindexes its former works and collections' do
      actor.destroy
      expect(actor).to have_received(:update_index_async)
    end
  end

  describe '#display_name' do
    let(:actor) { build(:actor, given_name: 'Pat', surname: 'Researcher') }

    context 'when nil' do
      before { actor.display_name = nil }

      it 'defaults to concatenated given and surname' do
        expect(actor.display_name).to eq 'Pat Researcher'
      end
    end

    context 'when set' do
      before { actor.display_name = 'Dr. Pat Q. Researcher PhD MD MLIS' }

      it 'returns the saved value' do
        expect(actor.display_name).to eq 'Dr. Pat Q. Researcher PhD MD MLIS'
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
    let(:actor) { create(:actor) }

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
end
