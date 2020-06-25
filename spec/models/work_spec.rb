# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Work, type: :model do
  it_behaves_like 'a resource with permissions' do
    let(:factory_name) { :work }
  end

  it_behaves_like 'a resource with a deposited at timestamp'

  describe 'table' do
    it { is_expected.to have_db_column(:work_type).of_type(:string) }
    it { is_expected.to have_db_column(:depositor_id) }
    it { is_expected.to have_db_column(:proxy_id) }
    it { is_expected.to have_db_column(:uuid).of_type(:uuid) }
    it { is_expected.to have_db_column(:doi).of_type(:string) }
    it { is_expected.to have_db_column(:embargoed_until).of_type(:datetime) }

    it { is_expected.to have_db_index(:depositor_id) }
    it { is_expected.to have_db_index(:proxy_id) }
  end

  describe 'factories' do
    it { is_expected.to have_valid_factory(:work) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:depositor).class_name('Actor').with_foreign_key(:depositor_id).inverse_of(:deposited_works) }
    it { is_expected.to belong_to(:proxy_depositor).class_name('Actor').with_foreign_key(:proxy_id).inverse_of(:proxy_deposited_works).optional }
    it { is_expected.to have_many(:access_controls) }
    it { is_expected.to have_many(:versions).class_name('WorkVersion').inverse_of('work') }
    it { is_expected.to have_many(:legacy_identifiers) }
    it { is_expected.to have_many(:collection_work_memberships) }
    it { is_expected.to have_many(:collections).through(:collection_work_memberships) }

    it { is_expected.to accept_nested_attributes_for(:versions) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:work_type) }
    it { is_expected.to validate_presence_of(:versions) }
  end

  describe '::Types' do
    subject(:types) { described_class::Types }

    describe '.all' do
      subject(:all) { types.all }

      specify do
        expect(all).to contain_exactly(
          'article',
          'audio',
          'book',
          'capstone_project',
          'conference_proceeding',
          'dataset',
          'dissertation',
          'image',
          'journal',
          'map_or_cartographic_material',
          'masters_culminating_experience',
          'masters_thesis',
          'other',
          'part_of_book',
          'poster',
          'presentation',
          'project',
          'report',
          'research_paper',
          'software_or_program_code',
          'thesis',
          'unspecified',
          'video'
        )
      end
    end

    describe '.default' do
      subject { types.default }

      it { is_expected.to eq('dataset') }
    end

    describe '.thesis' do
      subject { types.thesis }

      it { is_expected.to eq('thesis') }
    end

    describe '.unspecified' do
      subject { types.unspecified }

      it { is_expected.to eq('unspecified') }
    end

    describe '.options_for_select_box' do
      subject(:options) { types.options_for_select_box }

      it { is_expected.to include(['Dataset', 'dataset'], ['Part Of Book', 'part_of_book']) }
      it { is_expected.not_to include(['Unspecified', 'unspecified']) }
    end

    describe '.display' do
      it 'returns a human-readable version of the type' do
        expect(types.display(types.default)).to eq('Dataset')
      end
    end
  end

  describe '#work_type' do
    specify do
      expect(described_class.new).to define_enum_for(:work_type)
        .with_values(
          article: 'article',
          audio: 'audio',
          book: 'book',
          capstone_project: 'capstone_project',
          conference_proceeding: 'conference_proceeding',
          dataset: 'dataset',
          dissertation: 'dissertation',
          image: 'image',
          journal: 'journal',
          map_or_cartographic_material: 'map_or_cartographic_material',
          masters_culminating_experience: 'masters_culminating_experience',
          masters_thesis: 'masters_thesis',
          other: 'other',
          part_of_book: 'part_of_book',
          poster: 'poster',
          presentation: 'presentation',
          project: 'project',
          report: 'report',
          research_paper: 'research_paper',
          software_or_program_code: 'software_or_program_code',
          thesis: 'thesis',
          unspecified: 'unspecified',
          video: 'video'
        )
        .backed_by_column_of_type(:string)
    end
  end

  describe '.build_with_empty_version' do
    it 'builds a Work with one empty version' do
      work = described_class.build_with_empty_version
      expect(work.versions.length).to eq 1
    end

    it 'sets the version number to 1' do
      work = described_class.build_with_empty_version
      expect(work.versions.first.version_number).to eq 1
    end

    it 'passes through any arguments provided' do
      work_type = described_class::Types.all.first
      work = described_class.build_with_empty_version(work_type: work_type)
      expect(work.versions).to be_present
      expect(work.work_type).to eq work_type
    end

    it 'will not overwrite a provided version' do
      versions = [WorkVersion.new]
      new_work = described_class.build_with_empty_version(versions: versions)
      expect(new_work.versions).to match_array(versions)
    end
  end

  describe 'initialize' do
    it 'does not initialize a work version too' do
      expect(described_class.new.versions).to be_empty
    end

    it 'accepts initial work versions' do
      versions = [WorkVersion.new]
      new_work = described_class.new(versions: versions)
      expect(new_work.versions).to match_array(versions)
    end
  end

  describe 'version accessors' do
    subject(:work) { create :work, versions: [draft, v2, v1] }

    let(:draft) { build :work_version, :draft, title: 'Draft', work: nil, created_at: 1.day.ago }
    let(:v2) { build :work_version, :published, title: 'Published v2', work: nil, created_at: 2.days.ago }
    let(:v1) { build :work_version, :published, title: 'Published v1', work: nil, created_at: 3.days.ago }

    before { work.reload }

    describe '#latest_version' do
      it 'returns the latest version regardless of status' do
        expect(work.latest_version.title).to eq draft.title
      end
    end

    describe '#latest_published_version' do
      it 'returns the latest published version' do
        expect(work.latest_published_version.title).to eq v2.title
      end
    end

    describe '#draft_version' do
      context 'when a draft exists' do
        its(:draft_version) { is_expected.to eq draft }
      end

      context 'when no draft exists' do
        subject(:work) { create :work, versions: [v2, v1] }

        its(:draft_version) { is_expected.to be_nil }
      end
    end
  end

  describe '#to_solr' do
    context 'when the work only has a draft version' do
      subject { build(:work).to_solr }

      let(:keys) do
        %w(
          created_at_dtsi
          deposited_at_dtsi
          depositor_id_isi
          discover_groups_ssim
          discover_users_ssim
          doi_tesim
          embargoed_until_dtsi
          id
          model_ssi
          proxy_id_isi
          updated_at_dtsi
          uuid_ssi
          visibility_ssi
          work_type_ssim
        )
      end

      its(:keys) { is_expected.to contain_exactly(*keys) }
    end

    context 'when the work has a published version' do
      subject { create(:work, has_draft: false).to_solr }

      let(:keys) do
        %w(
          aasm_state_tesim
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
          embargoed_until_dtsi
          id
          identifier_tesim
          keyword_tesim
          language_tesim
          model_ssi
          proxy_id_isi
          published_date_tesim
          publisher_tesim
          related_url_tesim
          rights_tesim
          source_tesim
          subject_tesim
          subtitle_tesim
          title_tesim
          updated_at_dtsi
          uuid_ssi
          version_name_tesim
          version_number_isi
          visibility_ssi
          work_id_isi
          work_type_ssim
        )
      end

      its(:keys) { is_expected.to contain_exactly(*keys) }
    end
  end

  describe '#uuid' do
    subject(:work) { create(:work) }

    before { work.reload }

    its(:uuid) { is_expected.to match(/[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}/) }
  end

  describe '::reindex_all' do
    before do
      create(:work)
      allow(IndexingService).to receive(:commit)
      allow(WorkIndexer).to receive(:call)
    end

    it 'reindexes all the works and their versions into solr' do
      described_class.reindex_all
      expect(WorkIndexer).to have_received(:call).once
      expect(IndexingService).to have_received(:commit).once
    end

    context 'when given a relation' do
      let!(:special_work) { create(:work) }

      let(:only_special_works) { described_class.where(depositor: special_work.depositor) }

      it 'only reindexes works within that relation' do
        described_class.reindex_all(only_special_works)
        expect(WorkIndexer).to have_received(:call).once
        expect(WorkIndexer).to have_received(:call).with(special_work, anything)
      end
    end
  end

  describe 'embargoed?' do
    context 'with an unembargoed public work' do
      subject { build(:work, has_draft: false) }

      it { is_expected.not_to be_embargoed }
    end

    context 'with an embargoed public work' do
      subject { build(:work, has_draft: false, embargoed_until: (Time.zone.now + 6.days)) }

      it { is_expected.to be_embargoed }
    end

    context 'with an previously embargoed public work' do
      subject { build(:work, has_draft: false, embargoed_until: (Time.zone.now - 6.months)) }

      it { is_expected.not_to be_embargoed }
    end
  end

  describe '#count_view!' do
    context 'when the work has a published version' do
      let(:work) { build(:work) }
      let(:version) { instance_spy('version') }

      before { allow(work).to receive(:latest_published_version).and_return(version) }

      it 'calls the method on the published version' do
        work.count_view!
        expect(version).to have_received(:count_view!)
      end
    end

    context 'when the work does NOT have a published version' do
      let(:work) { build(:work) }

      it 'raises an error' do
        expect {
          work.count_view!
        }.to raise_error(ArgumentError, 'work must have a published version')
      end
    end
  end
end
