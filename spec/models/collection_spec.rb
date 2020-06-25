# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Collection, type: :model do
  it_behaves_like 'an indexable resource'

  it_behaves_like 'a resource with permissions' do
    let(:factory_name) { :collection }
  end

  it_behaves_like 'a resource with view statistics' do
    let(:resource) { create(:collection) }
  end

  it_behaves_like 'a resource with a deposited at timestamp'

  describe 'table' do
    it { is_expected.to have_db_column(:depositor_id) }
    it { is_expected.to have_db_column(:metadata).of_type(:jsonb) }
    it { is_expected.to have_db_column(:uuid).of_type(:uuid) }
    it { is_expected.to have_db_column(:doi).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:title).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:subtitle).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:keyword).of_type(:string).is_array.with_default([]) }
    it { is_expected.to have_jsonb_accessor(:description).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:contributor).of_type(:string).is_array.with_default([]) }
    it { is_expected.to have_jsonb_accessor(:publisher).of_type(:string).is_array.with_default([]) }
    it { is_expected.to have_jsonb_accessor(:published_date).of_type(:string) }
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
    it { is_expected.to have_many(:view_statistics) }

    describe 'default order of works' do
      let(:collection) { build :collection }

      # Note we create these records in the database "out of order"
      let!(:work_3) { create :work }
      let!(:work_1) { create :work }
      let!(:work_2) { create :work }

      before do
        # Note we create these records in the database "out of order"
        collection.collection_work_memberships.build(work: work_3, position: 3)
        collection.collection_work_memberships.build(work: work_1, position: 1)
        collection.collection_work_memberships.build(work: work_2, position: 2)

        collection.save!
      end

      it 'orders works by their position field, if available' do
        expect(collection.reload.works).to eq([work_1, work_2, work_3])

        # Update position of work_1 and ensure that the ordering follows suit
        collection.collection_work_memberships
          .find { |c_w_m| c_w_m.work == work_1 }
          .update!(position: 100)

        expect(collection.reload.works).to eq([work_2, work_3, work_1])
      end
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:description) }

    context 'with the :migration_api validation context' do
      it { is_expected.not_to validate_presence_of(:description).on(:migration_api) }
      it { is_expected.to allow_value('').for(:published_date).on(:migration_api) }
      it { is_expected.to allow_value('not an EDTF formatted date').for(:published_date).on(:migration_api) }
    end

    context 'without the :migration_api validation context' do
      let(:collection) { subject }

      it 'validates published_date is in EDTF format' do
        expect(collection).to allow_value('').for(:published_date)
        expect(collection).to allow_value('1999-uu-uu').for(:published_date)
        expect(collection).not_to allow_value('not an EDTF formatted date').for(:published_date)
      end
    end
  end

  describe 'multivalued fields' do
    it_behaves_like 'a multivalued json field', :keyword
    it_behaves_like 'a multivalued json field', :contributor
    it_behaves_like 'a multivalued json field', :publisher
    it_behaves_like 'a multivalued json field', :subject
    it_behaves_like 'a multivalued json field', :language
    it_behaves_like 'a multivalued json field', :identifier
    it_behaves_like 'a multivalued json field', :based_near
    it_behaves_like 'a multivalued json field', :related_url
    it_behaves_like 'a multivalued json field', :source
  end

  describe 'singlevalued fields' do
    it_behaves_like 'a singlevalued json field', :description
    it_behaves_like 'a singlevalued json field', :published_date
    it_behaves_like 'a singlevalued json field', :subtitle
  end

  describe '::reindex_all' do
    before do
      create(:collection)
      allow(IndexingService).to receive(:commit)
      allow(CollectionIndexer).to receive(:call)
    end

    it 'reindexes all the collections and their versions into solr' do
      described_class.reindex_all
      expect(CollectionIndexer).to have_received(:call).once
      expect(IndexingService).to have_received(:commit).once
    end

    context 'when given a relation' do
      let!(:special_collection) { create(:collection) }

      let(:only_special_collections) { described_class.where(depositor: special_collection.depositor) }

      it 'only reindexes collections within that relation' do
        described_class.reindex_all(only_special_collections)
        expect(CollectionIndexer).to have_received(:call).once
        expect(CollectionIndexer).to have_received(:call).with(special_collection, anything)
      end
    end
  end

  describe 'default attributes' do
    it 'defaults #visibility to "OPEN"' do
      expect(described_class.new.visibility).to eq Permissions::Visibility::OPEN
      expect(described_class.new(visibility: Permissions::Visibility::AUTHORIZED).visibility).to eq Permissions::Visibility::AUTHORIZED
    end
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

  describe '#to_solr' do
    context 'when the work only has a draft version' do
      subject { build(:collection).to_solr }

      let(:keys) do
        %w(
          based_near_tesim
          contributor_tesim
          created_at_dtsi
          creator_aliases_tesim
          creators_sim
          deposited_at_dtsi
          depositor_id_isi
          description_tesim
          discover_groups_ssim
          discover_users_ssim
          doi_tesim
          id
          identifier_tesim
          keyword_tesim
          language_tesim
          model_ssi
          published_date_tesim
          publisher_tesim
          related_url_tesim
          source_tesim
          subject_tesim
          subtitle_tesim
          title_tesim
          updated_at_dtsi
          uuid_ssi
          visibility_ssi
        )
      end

      its(:keys) { is_expected.to contain_exactly(*keys) }
    end

    context 'when the work has a published version' do
      subject { create(:collection, :with_creators, :with_complete_metadata).to_solr }

      let(:expected_keys) do
        %w(
          based_near_tesim
          contributor_tesim
          created_at_dtsi
          creator_aliases_tesim
          creators_sim
          deposited_at_dtsi
          depositor_id_isi
          description_tesim
          discover_groups_ssim
          discover_users_ssim
          doi_tesim
          id
          identifier_tesim
          keyword_tesim
          language_tesim
          model_ssi
          published_date_dtrsi
          published_date_tesim
          publisher_tesim
          related_url_tesim
          source_tesim
          subject_tesim
          subtitle_tesim
          title_tesim
          updated_at_dtsi
          uuid_ssi
          visibility_ssi
        )
      end

      its(:keys) { is_expected.to contain_exactly(*expected_keys) }
    end
  end

  describe 'after save' do
    let(:collection) { build :collection }

    # I've heard it's bad practice to mock the object under test, but I can't
    # think of a better way to do this without testing the contents of
    # update_index_async twice.

    it 'calls #update_index_async' do
      allow(collection).to receive(:update_index_async)
      collection.save!
      expect(collection).to have_received(:update_index_async)
    end
  end

  describe '#update_index_async' do
    let(:collection) { described_class.new }

    before { allow(SolrIndexingJob).to receive(:perform_later) }

    it 'provides itself to SolrIndexingJob.perform_later' do
      collection.update_index_async
      expect(SolrIndexingJob).to have_received(:perform_later).with(collection)
    end
  end

  describe '#update_index' do
    let(:collection) { described_class.new }

    before do
      allow(CollectionIndexer).to receive(:call)
      allow(collection).to receive(:reload)
    end

    context 'when the uuid is nil' do
      before { allow(collection).to receive(:uuid).and_return(nil) }

      it 'reloads the version and calls the CollectionIndexer' do
        collection.update_index
        expect(collection).to have_received(:reload)
        expect(CollectionIndexer).to have_received(:call)
      end
    end

    context 'when the uuid is present' do
      before { allow(collection).to receive(:uuid).and_return(SecureRandom.uuid) }

      it 'does NOT reload the version and calls the CollectionIndexer' do
        collection.update_index
        expect(collection).not_to have_received(:reload)
        expect(CollectionIndexer).to have_received(:call)
      end
    end
  end
end
