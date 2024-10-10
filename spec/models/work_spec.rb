# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Work, type: :model do
  it { is_expected.to delegate_method(:email).to(:depositor) }
  it { is_expected.to delegate_method(:display_name).to(:depositor) }
  it { is_expected.to delegate_method(:has_publisher_doi?).to(:latest_version) }

  it_behaves_like 'a resource with permissions' do
    let(:factory_name) { :work }
  end

  it_behaves_like 'a resource with a generated uuid' do
    let(:resource) { build(:work) }
  end

  it_behaves_like 'a resource with a deposited at timestamp'

  it_behaves_like 'a resource that can provide all DOIs in', [:doi, :latest_published_version_dois]

  it_behaves_like 'a resource with a thumbnail url' do
    let!(:work) { create :work, versions_count: 2 }
    let(:resource) { work }
  end

  it_behaves_like 'a resource with a thumbnail selection' do
    let!(:work) { create :work, versions_count: 2 }
    let(:resource) { work }
  end

  describe 'table' do
    it { is_expected.to have_db_column(:work_type).of_type(:string) }
    it { is_expected.to have_db_column(:depositor_id) }
    it { is_expected.to have_db_column(:proxy_id) }
    it { is_expected.to have_db_column(:doi).of_type(:string) }
    it { is_expected.to have_db_column(:embargoed_until).of_type(:datetime) }
    it { is_expected.to have_db_column(:deposit_agreed_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:deposit_agreement_version) }
    it { is_expected.to have_db_column(:thumbnail_selection).of_type(:string).with_options(default: ThumbnailSelections::DEFAULT_ICON) }
    it { is_expected.to have_db_column(:notify_editors).of_type(:boolean) }

    it { is_expected.to have_db_index(:depositor_id) }
    it { is_expected.to have_db_index(:proxy_id) }
  end

  describe 'factories' do
    it { is_expected.to have_valid_factory(:work) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:depositor).class_name('Actor').with_foreign_key(:depositor_id).inverse_of(:deposited_works) }
    it { is_expected.to belong_to(:proxy_depositor).class_name('Actor').with_foreign_key(:proxy_id).inverse_of(:proxy_deposited_works).optional }
    it { is_expected.to have_many(:curators).through(:curatorships) }
    it { is_expected.to have_many(:access_controls) }
    it { is_expected.to have_many(:versions).class_name('WorkVersion').inverse_of('work') }
    it { is_expected.to have_many(:legacy_identifiers) }
    it { is_expected.to have_many(:collection_work_memberships) }
    it { is_expected.to have_many(:collections).through(:collection_work_memberships) }
    it { is_expected.to have_one(:thumbnail_upload) }

    it { is_expected.to accept_nested_attributes_for(:versions) }
  end

  describe 'validations' do
    let(:work) { build(:work) }

    it { is_expected.to validate_presence_of(:work_type) }
    it { is_expected.to validate_presence_of(:versions) }

    context 'when embargoed_until is blank' do
      it 'is valid' do
        work.embargoed_until = nil
        expect(work.valid?).to eq true
      end
    end

    context 'when embargoed_until is within 4 years from now' do
      it 'is valid' do
        work.embargoed_until = DateTime.now + 1.year
        expect(work.valid?).to eq true
      end
    end

    context 'when embargoed_until is more than 4 years from now' do
      it 'is not valid' do
        work.embargoed_until = DateTime.now + 5.years
        expect(work.valid?).to eq false
      end
    end
  end

  describe '.recently_published' do
    let(:wv1) { build :work_version, :published, work: nil, sent_for_curation_at: nil }
    let(:work1) { create :work, versions: [wv1] }

    let(:wv2) { build :work_version, :published, work: nil, sent_for_curation_at: Time.now }
    let(:work2) { create :work, versions: [wv2] }

    let(:wv4) { build :work_version, work: nil, aasm_state: 'draft' }
    let(:work3) { create :work, versions: [wv4] }

    let(:work4) { create :work }

    it 'returns works with a published WorkVersion that has not been sent for curation' do
      expect(described_class.recently_published).to match_array([work1])
    end
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
          'professional_doctoral_culminating_experience',
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

      specify do
        expect(all).to be_frozen
      end
    end

    describe '.general' do
      subject(:general) { types.general }

      specify do
        expect(general).to contain_exactly(
          'audio',
          'image',
          'journal',
          'map_or_cartographic_material',
          'other',
          'poster',
          'presentation',
          'project',
          'unspecified',
          'video'
        )
      end

      specify do
        expect(general).to be_frozen
      end
    end

    describe '.scholarly_works' do
      subject(:scholarly_works) { types.scholarly_works }

      specify do
        expect(scholarly_works).to contain_exactly(
          'article',
          'book',
          'capstone_project',
          'conference_proceeding',
          'dissertation',
          'masters_thesis',
          'part_of_book',
          'report',
          'research_paper',
          'thesis'
        )
      end

      specify do
        expect(scholarly_works).to be_frozen
      end
    end

    describe '.data_and_code' do
      subject(:data_and_code) { types.data_and_code }

      specify do
        expect(data_and_code).to contain_exactly(
          'dataset',
          'software_or_program_code'
        )
      end

      specify do
        expect(data_and_code).to be_frozen
      end
    end

    describe '.grad_culminating_experiences' do
      subject(:grad_culminating_experiences) { types.grad_culminating_experiences }

      specify do
        expect(grad_culminating_experiences).to contain_exactly(
          'masters_culminating_experience',
          'professional_doctoral_culminating_experience'
        )
      end

      specify do
        expect(grad_culminating_experiences).to be_frozen
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

      it { expect(options).to include(['Dataset', 'dataset'],
                                      ['Part Of Book', 'part_of_book'],
                                      ['Masters Culminating Experience', 'masters_culminating_experience']) }

      it { is_expected.not_to include(['Unspecified', 'unspecified'], ['Masters Thesis', 'masters_thesis']) }
    end

    describe '.display' do
      it 'returns a human-readable version of the type' do
        expect(types.display(types.default)).to eq('Dataset')
      end
    end
  end

  describe '::DepositAgreement::CURRENT_VERSION' do
    subject { described_class::DepositAgreement::CURRENT_VERSION }

    it { is_expected.to eq('2.0') }
  end

  describe '#update_deposit_agreement' do
    context 'when the deposit agreement version is nil' do
      let(:work) { build(:work) }

      it 'updates the agreement version' do
        expect {
          work.update_deposit_agreement
        }.to change(work, :deposit_agreement_version).from(nil).to(described_class::DepositAgreement::CURRENT_VERSION)
      end
    end

    context 'when the work has the current deposit agreement version' do
      let(:work) { build(:work, deposit_agreement_version: described_class::DepositAgreement::CURRENT_VERSION) }

      it 'does NOT update the agreement version timestamp' do
        expect {
          work.update_deposit_agreement
        }.not_to(change(work, :deposit_agreed_at))
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
          professional_doctoral_culminating_experience: 'professional_doctoral_culminating_experience',
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
    let(:draft) { build :work_version, :draft, title: 'Draft', work: nil, created_at: 1.day.ago, version_number: 3 }
    let(:v2) { build :work_version, :published, title: 'Published v2', work: nil, created_at: 2.days.ago, version_number: 2 }
    let(:v1) { build :work_version, :published, title: 'Published v1', work: nil, created_at: 3.days.ago, version_number: 1 }
    let(:withdrawn) { build :work_version, :withdrawn, work: nil, created_at: 3.days.ago, version_number: 1 }

    before { work.reload }

    context 'with draft, published, and withdrawn versions' do
      subject(:work) { create :work, versions: [draft, v2, withdrawn] }

      it { is_expected.not_to be_withdrawn }

      its(:latest_version) { is_expected.to eq(draft) }
      its(:latest_published_version) { is_expected.to eq(v2) }
      its(:draft_version) { is_expected.to eq(draft) }
      its(:withdrawn_version) { is_expected.to eq(withdrawn) }
      its(:representative_version) { is_expected.to eq(v2) }
    end

    context 'with draft and published versions' do
      subject(:work) { create :work, versions: [draft, v2, v1] }

      it { is_expected.not_to be_withdrawn }

      its(:latest_version) { is_expected.to eq(draft) }
      its(:latest_published_version) { is_expected.to eq(v2) }
      its(:draft_version) { is_expected.to eq(draft) }
      its(:withdrawn_version) { is_expected.to be_nil }
      its(:representative_version) { is_expected.to eq(v2) }
    end

    context 'with draft and withdrawn versions' do
      subject(:work) { create :work, versions: [draft, withdrawn] }

      it { is_expected.to be_withdrawn }

      its(:latest_version) { is_expected.to eq(draft) }
      its(:latest_published_version) { is_expected.to be_nil }
      its(:draft_version) { is_expected.to eq(draft) }
      its(:withdrawn_version) { is_expected.to eq(withdrawn) }
      its(:representative_version) { is_expected.to eq(withdrawn) }
    end

    context 'with published and withdrawn versions' do
      subject(:work) { create :work, versions: [v2, withdrawn] }

      it { is_expected.not_to be_withdrawn }

      its(:latest_version) { is_expected.to eq(v2) }
      its(:latest_published_version) { is_expected.to eq(v2) }
      its(:draft_version) { is_expected.to be_nil }
      its(:withdrawn_version) { is_expected.to eq(withdrawn) }
      its(:representative_version) { is_expected.to eq(v2) }
    end

    context 'with only published versions' do
      subject(:work) { create :work, versions: [v2, v1] }

      it { is_expected.not_to be_withdrawn }

      its(:latest_version) { is_expected.to eq(v2) }
      its(:latest_published_version) { is_expected.to eq(v2) }
      its(:draft_version) { is_expected.to be_nil }
      its(:withdrawn_version) { is_expected.to be_nil }
      its(:representative_version) { is_expected.to eq(v2) }
    end

    context 'with only a draft version' do
      subject(:work) { create :work, versions: [draft] }

      it { is_expected.not_to be_withdrawn }

      its(:latest_version) { is_expected.to eq(draft) }
      its(:latest_published_version) { is_expected.to be_nil }
      its(:draft_version) { is_expected.to eq(draft) }
      its(:withdrawn_version) { is_expected.to be_nil }
      its(:representative_version) { is_expected.to eq(draft) }
    end

    context 'with only a withdrawn version' do
      subject(:work) { create :work, versions: [withdrawn] }

      it { is_expected.to be_withdrawn }

      its(:latest_version) { is_expected.to eq(withdrawn) }
      its(:latest_published_version) { is_expected.to be_nil }
      its(:draft_version) { is_expected.to be_nil }
      its(:withdrawn_version) { is_expected.to eq(withdrawn) }
      its(:representative_version) { is_expected.to eq(withdrawn) }
    end
  end

  describe '#resource_with_doi' do
    let(:work) { described_class.new }

    it 'returns `self`' do
      expect(work.resource_with_doi).to eq work
    end
  end

  describe '#to_solr' do
    context 'when the work only has a draft version' do
      subject { build(:work).to_solr }

      let(:keys) do
        %w(
          all_dois_ssim
          created_at_dtsi
          deposit_agreed_at_dtsi
          deposit_agreement_version_tesim
          deposited_at_dtsi
          depositor_id_isi
          discover_groups_ssim
          discover_users_ssim
          display_work_type_ssi
          doi_tesim
          edit_groups_ssim
          edit_users_ssim
          embargoed_until_dtsi
          id
          model_ssi
          proxy_id_isi
          read_groups_ssim
          read_users_ssim
          updated_at_dtsi
          uuid_ssi
          visibility_ssi
          work_type_ss
          thumbnail_url_ssi
          thumbnail_selection_tesim
          notify_editors_tesim
        )
      end

      its(:keys) { is_expected.to contain_exactly(*keys) }
    end

    context 'when the work has a published version' do
      subject { create(:work, has_draft: false).to_solr }

      let(:keys) do
        %w(
          aasm_state_tesim
          all_dois_ssim
          based_near_tesim
          contributor_tesim
          created_at_dtsi
          creators_sim
          creators_tesim
          deposit_agreed_at_dtsi
          deposit_agreement_version_tesim
          deposited_at_dtsi
          depositor_id_isi
          description_tesim
          discover_groups_ssim
          discover_users_ssim
          display_work_type_ssi
          doi_tesim
          draft_curation_requested_tesim
          accessibility_remediation_requested_tesim
          edit_groups_ssim
          edit_users_ssim
          embargoed_until_dtsi
          file_resource_ids_ssim
          file_version_titles_ssim
          id
          identifier_tesim
          keyword_sim
          keyword_tesim
          language_tesim
          mint_doi_requested_tesim
          model_ssi
          proxy_id_isi
          published_date_dtrsi
          published_date_tesim
          publisher_statement_tesim
          publisher_tesim
          read_groups_ssim
          read_users_ssim
          related_url_tesim
          rights_tesim
          sent_for_curation_at_dtsi
          source_tesim
          subject_sim
          subject_tesim
          subtitle_tesim
          title_ssort
          title_tesim
          updated_at_dtsi
          uuid_ssi
          version_name_tesim
          version_number_isi
          visibility_ssi
          work_id_isi
          work_type_ss
          thumbnail_url_ssi
          thumbnail_selection_tesim
          notify_editors_tesim
          external_app_id_isi
          published_at_dtsi
          removed_at_dtsi
          withdrawn_at_dtsi
          imported_metadata_from_rmd_tesim
          degree_tesim
          program_tesim
          sub_work_type_tesim
        )
      end

      its(:keys) { is_expected.to contain_exactly(*keys) }
    end
  end

  describe '::reindex_all' do
    before do
      create_list(:work, 2)
      allow(IndexingService).to receive(:commit)
      allow(WorkIndexer).to receive(:call)
    end

    context 'without any arguments' do
      it 'reindexes all the works and their versions into solr synchronously' do
        allow(SolrIndexingJob).to receive(:perform_later)
        described_class.reindex_all
        expect(WorkIndexer).to have_received(:call).twice
        expect(IndexingService).to have_received(:commit).once
        expect(SolrIndexingJob).not_to have_received(:perform_later)
      end
    end

    context 'when given a relation' do
      let!(:special_work) { create(:work) }

      let(:only_special_works) { described_class.where(depositor: special_work.depositor) }

      it 'only reindexes works within that relation' do
        allow(SolrIndexingJob).to receive(:perform_later)
        described_class.reindex_all(relation: only_special_works)
        expect(WorkIndexer).to have_received(:call).once
        expect(WorkIndexer).to have_received(:call).with(special_work, anything)
        expect(SolrIndexingJob).not_to have_received(:perform_later)
      end
    end

    context 'with async: true' do
      it 'reindexes all the works and their versions into solr asynchronously' do
        allow(SolrIndexingJob).to receive(:perform_later)
        described_class.reindex_all(async: true)
        expect(WorkIndexer).not_to have_received(:call)
        expect(IndexingService).not_to have_received(:commit)
        expect(SolrIndexingJob).to have_received(:perform_later).once.with(kind_of(described_class), commit: false)
        expect(SolrIndexingJob).to have_received(:perform_later).once.with(kind_of(described_class), commit: true)
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
      subject { work.count_view! }

      let(:work) { build(:work) }

      it { is_expected.to be_nil }
    end
  end

  describe '#stats' do
    subject(:work) { create :work, versions_count: 3, has_draft: true }

    before { allow(AggregateViewStatistics).to receive(:call).and_return(:returned_stats) }

    it 'Passes all published works to AggregateViewStatistics' do
      expect(work.stats).to eq :returned_stats
      expect(AggregateViewStatistics).to have_received(:call).with(models: work.versions.published)
    end
  end

  describe '#thumbnail_urls' do
    let(:mock_attacher) { instance_double FileUploader::Attacher }
    let!(:work) { create :work, versions_count: 2 }

    context "when work's latest_published_version has multiple file_resources with thumbnail urls" do
      before do
        work.latest_published_version.file_resources << (create :file_resource)
        work.save
        allow(mock_attacher).to receive(:url).with(:thumbnail).and_return 'url.com/path/file'
      end

      it 'returns an array containing each of the thumbnail urls from the file_resources' do
        allow_any_instance_of(FileResource).to receive(:file_attacher).and_return(mock_attacher)
        expect(work.send(:auto_generated_thumbnail_urls).count).to eq 2
        expect(work.send(:auto_generated_thumbnail_urls).class).to eq Array
        expect(work.send(:auto_generated_thumbnail_urls).last).to eq 'url.com/path/file'
      end
    end
  end

  describe '#latest_published_version_dois' do
    let!(:work) { create :work }
    let(:work_version) do
      create :work_version, :published,
             doi: '10.26207/utaj-jfhi',
             identifier: '10.26207/xyz-lmno'
    end

    before do
      work.versions << work_version
      work.save!
    end

    it "returns an array of dois from the works's latest published version" do
      expect(work.latest_published_version_dois).to eq([work_version.doi, work_version.identifier].flatten.map { |n| "doi:#{n}" })
    end
  end

  describe '#current_curator_access_id' do
    let(:work) { create(:work) }
    let(:curatorship1) { create(:curatorship, work: work, created_at: '2024-02-10') }
    let(:curatorship2) { create(:curatorship, work: work, created_at: '2024-02-13') }

    let(:user1)  { create(:user, access_id: 'abc1234') }
    let(:user2)  { create(:user, access_id: 'xyz9876') }

    before do
      curatorship1.update(user: user1)
      curatorship2.update(user: user2)
    end

    it 'returns the access id of the most recent curator' do
      expect(work.current_curator_access_id).to eq 'xyz9876'
    end
  end
end
