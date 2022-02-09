# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Collection, type: :model do
  it_behaves_like 'a resource with permissions' do
    let(:factory_name) { :collection }
  end

  it_behaves_like 'a resource with view statistics' do
    let(:resource) { create(:collection) }
  end

  it_behaves_like 'a resource with a generated uuid' do
    let(:resource) { build(:collection) }
  end

  it_behaves_like 'a resource with a deposited at timestamp'

  it_behaves_like 'a resource that can provide all DOIs in', [:doi, :identifier]

  it_behaves_like 'a resource with a thumbnail url' do
    let!(:resource) { create :collection }

    before do
      create :work, versions_count: 2, collections: [resource]
    end
  end

  describe 'table' do
    it { is_expected.to have_db_column(:depositor_id) }
    it { is_expected.to have_db_column(:metadata).of_type(:jsonb) }
    it { is_expected.to have_db_column(:doi).of_type(:string) }
    it { is_expected.to have_db_column(:auto_generate_thumbnail).of_type(:boolean).with_options(default: false) }
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
    it { is_expected.to have_many(:creators) }
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
    let(:collection) { subject }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:description) }

    it 'validates published_date is in EDTF format' do
      expect(collection).to allow_value('').for(:published_date)
      expect(collection).to allow_value('1999-uu-uu').for(:published_date)
      expect(collection).not_to allow_value('not an EDTF formatted date').for(:published_date)
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
      allow(SolrIndexingJob).to receive(:perform_later)
    end

    context 'with the defaults' do
      it 'reindexes all the collections and their versions into solr' do
        described_class.reindex_all
        expect(SolrIndexingJob).not_to have_received(:perform_later)
        expect(CollectionIndexer).to have_received(:call).once
        expect(IndexingService).to have_received(:commit).once
      end
    end

    context 'when given a relation' do
      let!(:special_collection) { create(:collection) }

      let(:only_special_collections) { described_class.where(depositor: special_collection.depositor) }

      it 'only reindexes collections within that relation' do
        described_class.reindex_all(relation: only_special_collections)
        expect(CollectionIndexer).to have_received(:call).once
        expect(CollectionIndexer).to have_received(:call).with(special_collection, anything)
      end
    end

    context 'when indexing async' do
      it 'runs the job later' do
        described_class.reindex_all(async: true)
        expect(SolrIndexingJob).to have_received(:perform_later).once
        expect(CollectionIndexer).not_to have_received(:call)
        expect(IndexingService).to have_received(:commit).once
      end
    end
  end

  describe 'default attributes' do
    it 'defaults #visibility to "OPEN"' do
      expect(described_class.new.visibility).to eq Permissions::Visibility::OPEN
      expect(described_class.new(visibility: Permissions::Visibility::AUTHORIZED).visibility).to eq Permissions::Visibility::AUTHORIZED
    end
  end

  describe '#build_creator' do
    let(:actor) { build_stubbed :actor }
    let(:collection) { build_stubbed :collection }

    it 'builds a creator for the given Actor but does not persist it' do
      expect {
        collection.build_creator(actor: actor)
      }.to change {
        collection.creators.length
      }.by(1)

      collection.creators.first.tap do |creator|
        expect(creator).not_to be_persisted
        expect(creator.actor).to eq actor
        expect(creator.display_name).to eq actor.display_name
      end
    end

    it 'is idempotent' do
      expect {
        2.times { collection.build_creator(actor: actor) }
      }.to change {
        collection.creators.length
      }.by(1)
    end
  end

  describe '#resource_with_doi' do
    let(:collection) { described_class.new }

    it 'returns `self`' do
      expect(collection.resource_with_doi).to eq collection
    end
  end

  describe '#to_solr' do
    subject { create(:collection, :with_creators, :with_complete_metadata).to_solr }

    let(:expected_keys) do
      %w(
        all_dois_ssim
        based_near_tesim
        contributor_tesim
        created_at_dtsi
        creators_tesim
        creators_sim
        deposited_at_dtsi
        depositor_id_isi
        description_tesim
        discover_groups_ssim
        discover_users_ssim
        display_work_type_ssi
        doi_tesim
        edit_groups_ssim
        edit_users_ssim
        id
        identifier_tesim
        keyword_sim
        keyword_tesim
        language_tesim
        model_ssi
        published_date_dtrsi
        published_date_tesim
        publisher_tesim
        read_groups_ssim
        read_users_ssim
        related_url_tesim
        source_tesim
        subject_sim
        subject_tesim
        subtitle_tesim
        title_ssort
        title_tesim
        updated_at_dtsi
        uuid_ssi
        visibility_ssi
        work_type_ss
        thumbnail_url_ssi
        auto_generate_thumbnail_tesim
      )
    end

    its(:keys) { is_expected.to contain_exactly(*expected_keys) }
  end

  describe 'after save' do
    let(:collection) { build :collection }

    # I've heard it's bad practice to mock the object under test, but I can't
    # think of a better way to do this without testing the contents of
    # perform_update_index twice.

    it 'calls #perform_update_index' do
      allow(collection).to receive(:perform_update_index)
      collection.save!
      expect(collection).to have_received(:perform_update_index)
    end
  end

  describe '#perform_update_index' do
    let(:collection) { described_class.new }

    before { allow(SolrIndexingJob).to receive(:perform_later) }

    it 'provides itself to SolrIndexingJob.perform_later' do
      collection.send(:perform_update_index)
      expect(SolrIndexingJob).to have_received(:perform_later).with(collection)
    end
  end

  describe '#perform_update_doi' do
    let(:collection) { described_class.new }

    before do
      allow(CollectionIndexer).to receive(:call)
      allow(DoiUpdatingJob).to receive(:perform_later)
    end

    context 'when the doi is not flagged for update' do
      let(:collection) { build(:collection) }

      it 'does not send anything to DataCite' do
        collection.save
        expect(DoiUpdatingJob).not_to have_received(:perform_later)
      end
    end

    context 'when the collection has a doi' do
      let(:collection) { build(:collection, :with_a_doi) }

      it 'updates the metadata with DataCite' do
        collection.update_doi = true
        collection.save
        expect(DoiUpdatingJob).to have_received(:perform_later).with(collection)
      end
    end

    context 'when the collection does NOT have a doi' do
      let(:collection) { build(:collection) }

      it 'does NOT send any updates to DataCite' do
        collection.doi = nil
        collection.update_doi = true
        collection.save
        expect(DoiUpdatingJob).not_to have_received(:perform_later)
      end
    end
  end

  describe '#update_index' do
    let(:collection) { build(:collection) }

    before { allow(CollectionIndexer).to receive(:call) }

    context 'with defaults' do
      it 'calls the CollectionIndexer' do
        collection.update_index
        expect(CollectionIndexer).to have_received(:call).with(collection, commit: true)
      end
    end

    context 'when specifing NOT to commit' do
      it 'calls the CollectionIndexer' do
        collection.update_index(commit: false)
        expect(CollectionIndexer).to have_received(:call).with(collection, commit: false)
      end
    end
  end

  describe 'after destroy' do
    let(:collection) { create(:collection) }

    before { allow(SolrDeleteJob).to receive(:perform_now) }

    it 'removes the collection from the index' do
      collection.destroy
      expect(SolrDeleteJob).to have_received(:perform_now).with(collection.uuid)
    end
  end

  describe '#creators' do
    let(:resource) { create(:collection, :with_creators, creator_count: 2) }

    it_behaves_like 'a resource with orderable creators'
  end

  describe '#thumbnail_present?' do
    let(:mock_attacher) { instance_double FileUploader::Attacher }
    let!(:collection) { create :collection }

    before do
      create :work, versions_count: 2, collections: [collection]
    end

    context 'when a thumbnail url is found' do
      before do
        allow(mock_attacher).to receive(:url).with(:thumbnail).and_return 'url.com/path/file'
      end

      it 'returns true' do
        allow_any_instance_of(FileResource).to receive(:file_attacher).and_return(mock_attacher)
        expect(collection.thumbnail_present?).to eq true
      end
    end

    context 'when a thumbnail url is not found' do
      before do
        allow(mock_attacher).to receive(:url).with(:thumbnail).and_return nil
      end

      it 'returns false' do
        allow_any_instance_of(FileResource).to receive(:file_attacher).and_return(mock_attacher)
        expect(collection.thumbnail_present?).to eq false
      end
    end
  end

  describe '#thumbnail_urls' do
    let(:mock_attacher) { instance_double FileUploader::Attacher }
    let!(:collection) { create :collection }

    before do
      create :work, versions_count: 2, collections: [collection]
      create :work, versions_count: 3, collections: [collection]
    end

    context 'when collection has many works with thumbnail urls' do
      before do
        allow(mock_attacher).to receive(:url).with(:thumbnail).and_return 'url.com/path/file'
      end

      it "returns an array containing each work's latest_published_version's thumbnail urls" do
        allow_any_instance_of(FileResource).to receive(:file_attacher).and_return(mock_attacher)
        expect(collection.send(:thumbnail_urls).count).to eq 2
        expect(collection.send(:thumbnail_urls).class).to eq Array
        expect(collection.send(:thumbnail_urls).last).to eq 'url.com/path/file'
      end
    end
  end
end
