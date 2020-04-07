# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkVersion, type: :model do
  describe 'table' do
    it { is_expected.to have_db_column(:work_id) }
    it { is_expected.to have_db_index(:work_id) }
    it { is_expected.to have_db_column(:aasm_state) }
    it { is_expected.to have_db_column(:metadata).of_type(:jsonb) }
    it { is_expected.to have_db_column(:uuid).of_type(:uuid) }
    it { is_expected.to have_db_column(:version_number).of_type(:integer) }
    it { is_expected.to have_db_column(:doi).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:title).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:subtitle).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:version_name).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:keyword).of_type(:string).is_array.with_default([]) }
    it { is_expected.to have_jsonb_accessor(:rights).of_type(:string) }
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
  end

  describe 'factory' do
    it { is_expected.to have_valid_factory(:work_version) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:work) }
    it { is_expected.to have_many(:file_version_memberships) }
    it { is_expected.to have_many(:file_resources).through(:file_version_memberships) }
    it { is_expected.to have_many(:creator_aliases) }
    it { is_expected.to have_many(:creators).through(:creator_aliases) }
    it { is_expected.to be_versioned }

    it { is_expected.to accept_nested_attributes_for(:file_resources) }
    it { is_expected.to accept_nested_attributes_for(:creator_aliases).allow_destroy(true) }
  end

  describe 'states' do
    it { is_expected.to have_state(:draft) }
    it { is_expected.to transition_from(:draft).to(:published).on_event(:publish) }
    it { is_expected.to transition_from(:published).to(:withdrawn).on_event(:withdraw) }
    it { is_expected.to transition_from(:withdrawn).to(:published).on_event(:publish) }
    it { is_expected.to transition_from(:draft).to(:removed).on_event(:remove) }
    it { is_expected.to transition_from(:withdrawn).to(:removed).on_event(:remove) }
  end

  describe 'validations' do
    subject(:work_version) { build(:work_version) }

    context 'when draft' do
      it { is_expected.to validate_presence_of(:title) }
    end

    context 'when published' do
      before { work_version.publish }

      it { is_expected.to validate_presence_of(:title) }

      it 'validates the presence of files' do
        work_version.file_resources = []
        work_version.validate
        expect(work_version.errors[:file_resources]).not_to be_empty
        work_version.file_resources.build
        work_version.validate
        expect(work_version.errors[:file_resources]).to be_empty
      end

      it 'validates the presence of creators' do
        work_version.creator_aliases = []
        work_version.validate
        expect(work_version.errors[:creator_aliases]).not_to be_empty
        work_version.creator_aliases.build(attributes_for(:work_version_creation))
        work_version.validate
        expect(work_version.errors[:creator_aliases]).to be_empty
      end

      it 'validates the visibility of the work' do
        work_version.work.access_controls.destroy_all
        work_version.validate
        expect(work_version.errors[:visibility]).to eq(['cannot be private'])
        work_version.work.grant_open_access
        work_version.validate
        expect(work_version.errors[:visibility]).to be_empty
      end
    end

    context 'with the version number' do
      before { work_version.version_number = 1 }

      it { is_expected.to validate_uniqueness_of(:version_number).scoped_to(:work_id) }
      it { is_expected.to validate_presence_of(:version_number) }
    end
  end

  describe 'multivalued fields' do
    it_behaves_like 'a multivalued json field', :keyword
    it_behaves_like 'a multivalued json field', :description
    it_behaves_like 'a multivalued json field', :resource_type
    it_behaves_like 'a multivalued json field', :contributor
    it_behaves_like 'a multivalued json field', :publisher
    it_behaves_like 'a multivalued json field', :published_date
    it_behaves_like 'a multivalued json field', :subject
    it_behaves_like 'a multivalued json field', :language
    it_behaves_like 'a multivalued json field', :identifier
    it_behaves_like 'a multivalued json field', :based_near
    it_behaves_like 'a multivalued json field', :related_url
    it_behaves_like 'a multivalued json field', :source
  end

  describe 'singlevalued fields' do
    it_behaves_like 'a singlevalued json field', :subtitle
    it_behaves_like 'a singlevalued json field', :rights
    it_behaves_like 'a singlevalued json field', :version_name
  end

  it { is_expected.to delegate_method(:depositor).to(:work) }
  it { is_expected.to delegate_method(:proxy_depositor).to(:work) }
  it { is_expected.to delegate_method(:embargoed?).to(:work) }

  describe '#uuid' do
    subject(:work_version) { create(:work_version) }

    before { work_version.reload }

    its(:uuid) { is_expected.to match(/[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}/) }
  end

  describe '#build_creator_alias' do
    let(:actor) { build_stubbed :actor }
    let(:work_version) { build_stubbed :work_version, :with_creators, creator_count: 0 }

    it 'builds a creator_alias for the given Actor but does not persist it' do
      expect {
        work_version.build_creator_alias(actor: actor)
      }.to change {
        work_version.creator_aliases.length
      }.by(1)

      work_version.creator_aliases.first.tap do |creator_alias|
        expect(creator_alias).not_to be_persisted
        expect(creator_alias.actor).to eq actor
        expect(creator_alias.alias).to eq actor.default_alias
      end
    end

    it 'is idempotent' do
      expect {
        2.times { work_version.build_creator_alias(actor: actor) }
      }.to change {
        work_version.creator_aliases.length
      }.by(1)
    end
  end

  describe '#latest_published_version?' do
    subject { work.versions.last }

    context 'when there is no published version' do
      let(:work) { create(:work) }

      it { is_expected.not_to be_latest_published_version }
    end

    context 'when there is a published version' do
      let(:work) { create(:work, versions_count: 2, has_draft: false) }

      it { is_expected.to be_latest_published_version }
    end
  end

  describe '#to_solr' do
    subject(:work_version) { create(:work_version) }

    its(:to_solr) do
      is_expected.to include(
        title_tesim: [work_version.title],
        latest_version_bsi: false,
        work_type_tesim: 'dataset'
      )
    end
  end

  describe '#update_index' do
    let(:work_version) { described_class.new }

    before do
      allow(WorkIndexer).to receive(:call)
      allow(work_version).to receive(:reload)
    end

    context 'when the uuid is nil' do
      before { allow(work_version).to receive(:uuid).and_return(nil) }

      it 'reloads the version and calls the WorkIndexer' do
        work_version.update_index
        expect(work_version).to have_received(:reload)
        expect(WorkIndexer).to have_received(:call)
      end
    end

    context 'when the uuid is present' do
      before { allow(work_version).to receive(:uuid).and_return(SecureRandom.uuid) }

      it 'does NOT reload the version and calls the WorkIndexer' do
        work_version.update_index
        expect(work_version).not_to have_received(:reload)
        expect(WorkIndexer).to have_received(:call)
      end
    end
  end
end
