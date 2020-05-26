# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Work, type: :model do
  it_behaves_like 'a resource with permissions' do
    let(:factory_name) { :work }
  end

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
    it { is_expected.to belong_to(:proxy_depositor).class_name('Actor').with_foreign_key(:proxy_id).inverse_of(:proxy_deposited_works) }
    it { is_expected.to have_many(:access_controls) }
    it { is_expected.to have_many(:versions).class_name('WorkVersion').inverse_of('work') }
    it { is_expected.to have_many(:legacy_identifiers) }
    it { is_expected.to have_many(:collection_work_memberships) }
    it { is_expected.to have_many(:collections).through(:collection_work_memberships) }

    it { is_expected.to accept_nested_attributes_for(:versions) }
  end

  describe 'validations' do
    it { is_expected.to validate_inclusion_of(:work_type).in_array(Work::Types.all) }
    it { is_expected.to validate_presence_of(:versions) }
  end

  describe '::Types' do
    subject(:types) { described_class::Types }

    describe '.all' do
      subject(:all) { types.all }

      specify do
        expect(all).to contain_exactly(
          types::ARTICLE,
          types::AUDIO,
          types::BOOK,
          types::CAPSTONE_PROJECT,
          types::CONFERENCE_PROCEEDING,
          types::DATASET,
          types::DISSERTATION,
          types::IMAGE,
          types::JOURNAL,
          types::MAP_OR_CARTOGRAPHIC_MATERIAL,
          types::MASTERS_CULMINATING_EXPERIENCE,
          types::MASTERS_THESIS,
          types::OTHER,
          types::PART_OF_BOOK,
          types::POSTER,
          types::PRESENTATION,
          types::PROJECT,
          types::REPORT,
          types::RESEARCH_PAPER,
          types::SOFTWARE_OR_PROGRAM_CODE,
          types::VIDEO
        )
      end
    end

    describe '.default' do
      subject { types.default }

      it { is_expected.to eq(types::DATASET) }
    end

    describe '.options_for_select_box' do
      subject(:options) { types.options_for_select_box }

      specify do
        expect(options).to contain_exactly(
          ['Article', types::ARTICLE],
          ['Audio', types::AUDIO],
          ['Book', types::BOOK],
          ['Capstone Project', types::CAPSTONE_PROJECT],
          ['Conference Proceeding', types::CONFERENCE_PROCEEDING],
          ['Dataset', types::DATASET],
          ['Dissertation', types::DISSERTATION],
          ['Image', types::IMAGE],
          ['Journal', types::JOURNAL],
          ['Map Or Cartographic Material', types::MAP_OR_CARTOGRAPHIC_MATERIAL],
          ['Masters Culminating Experience', types::MASTERS_CULMINATING_EXPERIENCE],
          ['Masters Thesis', types::MASTERS_THESIS],
          ['Other', types::OTHER],
          ['Part Of Book', types::PART_OF_BOOK],
          ['Poster', types::POSTER],
          ['Presentation', types::PRESENTATION],
          ['Project', types::PROJECT],
          ['Report', types::REPORT],
          ['Research Paper', types::RESEARCH_PAPER],
          ['Software Or Program Code', types::SOFTWARE_OR_PROGRAM_CODE],
          ['Video', types::VIDEO]
        )
      end
    end

    describe '.display' do
      it 'returns a human-readable version of the type' do
        {
          types::ARTICLE => 'Article',
          types::AUDIO => 'Audio',
          types::BOOK => 'Book',
          types::CAPSTONE_PROJECT => 'Capstone Project',
          types::CONFERENCE_PROCEEDING => 'Conference Proceeding',
          types::DATASET => 'Dataset',
          types::DISSERTATION => 'Dissertation',
          types::IMAGE => 'Image',
          types::JOURNAL => 'Journal',
          types::MAP_OR_CARTOGRAPHIC_MATERIAL => 'Map Or Cartographic Material',
          types::MASTERS_CULMINATING_EXPERIENCE => 'Masters Culminating Experience',
          types::MASTERS_THESIS => 'Masters Thesis',
          types::OTHER => 'Other',
          types::PART_OF_BOOK => 'Part Of Book',
          types::POSTER => 'Poster',
          types::PRESENTATION => 'Presentation',
          types::PROJECT => 'Project',
          types::REPORT => 'Report',
          types::RESEARCH_PAPER => 'Research Paper',
          types::SOFTWARE_OR_PROGRAM_CODE => 'Software Or Program Code',
          types::VIDEO => 'Video'
        }.each do |type, expected_output|
          expect(types.display(type)).to eq expected_output
        end
      end
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
          depositor_id_isi
          proxy_id_isi
          discover_groups_ssim
          discover_users_ssim
          doi_tesim
          embargoed_until_dtsi
          id
          model_ssi
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
          depositor_id_isi
          proxy_id_isi
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
  end

  describe 'embargoed?' do
    context 'with an unembargoed public work' do
      subject { build(:work, has_draft: false) }

      it { is_expected.not_to be_embargoed }
    end

    context 'with an embargoed public work' do
      subject { build(:work, has_draft: false, embargoed_until: (DateTime.now + 6.days)) }

      it { is_expected.to be_embargoed }
    end

    context 'with an previously embargoed public work' do
      subject { build(:work, has_draft: false, embargoed_until: (DateTime.now - 6.months)) }

      it { is_expected.not_to be_embargoed }
    end
  end
end
