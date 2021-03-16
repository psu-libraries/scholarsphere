# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkVersion, type: :model do
  it_behaves_like 'a resource with view statistics' do
    let(:resource) { create(:work_version) }
  end

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
    it { is_expected.to have_jsonb_accessor(:description).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:resource_type).of_type(:string).is_array.with_default([]) }
    it { is_expected.to have_jsonb_accessor(:contributor).of_type(:string).is_array.with_default([]) }
    it { is_expected.to have_jsonb_accessor(:publisher).of_type(:string).is_array.with_default([]) }
    it { is_expected.to have_jsonb_accessor(:published_date).of_type(:string) }
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
    it { is_expected.to have_many(:creators) }
    it { is_expected.to have_many(:view_statistics) }
    it { is_expected.to be_versioned }

    it { is_expected.to accept_nested_attributes_for(:file_resources) }
    it { is_expected.to accept_nested_attributes_for(:creators).allow_destroy(true) }

    describe '#creators' do
      let(:resource) { create(:work_version, :with_creators, creator_count: 2) }

      it_behaves_like 'a resource with orderable creators'
    end
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

      it { is_expected.not_to validate_presence_of(:published_date) }
    end

    context 'when published' do
      before { work_version.publish }

      it { is_expected.to validate_presence_of(:title) }
      it { is_expected.to validate_presence_of(:description) }

      it 'validates the presence of files' do
        work_version.file_resources = []
        work_version.validate
        expect(work_version.errors[:file_resources]).not_to be_empty
        work_version.file_resources.build
        work_version.validate
        expect(work_version.errors[:file_resources]).to be_empty
      end

      it 'validates the presence of creators' do
        work_version.creators = []
        work_version.validate
        expect(work_version.errors[:creators]).not_to be_empty
        work_version.creators.build(attributes_for(:authorship))
        work_version.validate
        expect(work_version.errors[:creators]).to be_empty
      end

      it 'validates the visibility of the work' do
        work_version.work.access_controls.destroy_all
        work_version.validate
        expect(work_version.errors[:visibility]).to eq(['cannot be private'])
        work_version.work.grant_open_access
        work_version.validate
        expect(work_version.errors[:visibility]).to be_empty
      end

      it { is_expected.to validate_presence_of(:published_date) }

      it 'validates published_date is in EDTF format' do
        expect(work_version).to allow_value('1999-uu-uu').for(:published_date)
        expect(work_version).not_to allow_value('not an EDTF formatted date').for(:published_date)
      end

      context 'with the :migration_api validation context' do
        it { is_expected.to allow_value(nil).for(:description).on(:migration_api) }
        it { is_expected.to allow_value(nil).for(:published_date).on(:migration_api) }

        it { is_expected.to allow_value('not an EDTF formatted date').for(:published_date).on(:migration_api) }
      end
    end

    context 'with the version number' do
      it { is_expected.to validate_uniqueness_of(:version_number).scoped_to(:work_id) }
      it { is_expected.to validate_presence_of(:version_number) }
    end

    context 'with a version name' do
      it { is_expected.to allow_value(nil).for(:version_name) }
      it { is_expected.to allow_value('1.0.1').for(:version_name) }
      it { is_expected.to allow_value('1.2.3-beta').for(:version_name) }
      it { is_expected.not_to allow_value('1').for(:version_name) }
      it { is_expected.not_to allow_value('1.0').for(:version_name) }
      it { is_expected.not_to allow_value('v1').for(:version_name) }
    end
  end

  describe 'multivalued fields' do
    it_behaves_like 'a multivalued json field', :keyword
    it_behaves_like 'a multivalued json field', :resource_type
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
    it_behaves_like 'a singlevalued json field', :rights
    it_behaves_like 'a singlevalued json field', :subtitle
    it_behaves_like 'a singlevalued json field', :version_name
  end

  it { is_expected.to delegate_method(:depositor).to(:work) }
  it { is_expected.to delegate_method(:proxy_depositor).to(:work) }
  it { is_expected.to delegate_method(:embargoed?).to(:work) }
  it { is_expected.to delegate_method(:work_type).to(:work) }
  it { is_expected.to delegate_method(:deposited_at).to(:work) }

  describe 'after save' do
    let(:work_version) { build :work_version, :published }

    # I've heard it's bad practice to mock the object under test, but I can't
    # think of a better way to do this without testing the contents of
    # perform_update_index twice.

    it 'calls #perform_update_index' do
      allow(work_version).to receive(:perform_update_index)
      work_version.save!
      expect(work_version).to have_received(:perform_update_index)
    end
  end

  describe '.build_with_empty_work' do
    let(:depositor) { build :actor, surname: 'Expected Depositor' }

    it 'builds a WorkVersion with an initialized work' do
      wv = described_class.build_with_empty_work(depositor: depositor)
      expect(wv.work).to be_present
    end

    it 'forces the version number to 1' do
      wv = described_class.build_with_empty_work(depositor: depositor)
      expect(wv.version_number).to eq 1

      wv = described_class.build_with_empty_work({ version_number: 1000 }, depositor: depositor)
      expect(wv.version_number).to eq 1
    end

    it 'defaults the visiblity to OPEN' do
      wv = described_class.build_with_empty_work(depositor: depositor)
      expect(wv.work.visibility).to eq Permissions::Visibility::OPEN
    end

    it 'forces the depositor to the one provided' do
      depositor.save
      wv = described_class.build_with_empty_work(depositor: depositor)
      expect(wv.work.depositor).to eq depositor

      # Try to provide our own depositor as an object
      wv = described_class.build_with_empty_work({
                                                   work_attributes: { depositor: create(:actor) }
                                                 }, depositor: depositor)
      expect(wv.work.depositor).to eq depositor

      # Try to provide our own depositor as an id
      wv = described_class.build_with_empty_work({
                                                   work_attributes: { depositor_id: create(:actor).id }
                                                 }, depositor: depositor)
      expect(wv.work.depositor).to eq depositor
    end

    it 'initializes the Work with the Version that its just built' do
      wv = described_class.build_with_empty_work({
                                                   title: 'My work',
                                                   work_attributes: {
                                                     work_type: Work::Types.all.first
                                                   }
                                                 },
                                                 depositor: depositor)

      expect(wv.work.versions).to contain_exactly(wv)
    end

    it 'passes through attributes provided' do
      wv = described_class.build_with_empty_work({
                                                   title: 'my title',
                                                   work_attributes: {
                                                     work_type: Work::Types.all.first
                                                   }
                                                 },
                                                 depositor: depositor)

      expect(wv.title).to eq 'my title'
      expect(wv.work.work_type).to eq Work::Types.all.first
    end
  end

  describe '#uuid' do
    subject(:work_version) { create(:work_version) }

    before { work_version.reload }

    its(:uuid) { is_expected.to match(/[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}/) }
  end

  describe '#resource_with_doi' do
    let(:work) { build_stubbed :work }
    let(:work_version) { described_class.new(work: work) }

    it 'returns the parent work' do
      expect(work_version.resource_with_doi).to eq work
    end
  end

  describe '#build_creator' do
    let(:actor) { build_stubbed :actor }
    let(:work_version) { build_stubbed :work_version, :with_creators, creator_count: 0 }

    it 'builds a creator for the given Actor but does not persist it' do
      expect {
        work_version.build_creator(actor: actor)
      }.to change {
        work_version.creators.length
      }.by(1)

      work_version.creators.first.tap do |creator|
        expect(creator).not_to be_persisted
        expect(creator.actor).to eq actor
        expect(creator.display_name).to eq actor.display_name
      end
    end

    it 'is idempotent' do
      expect {
        2.times { work_version.build_creator(actor: actor) }
      }.to change {
        work_version.creators.length
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

  describe '#latest_version?' do
    subject { work.versions.last }

    let(:work) { create(:work) }

    it { is_expected.to be_latest_version }
  end

  describe '#to_solr' do
    subject(:work_version) { create(:work_version, published_date: '1999-uu-uu') }

    its(:to_solr) do
      is_expected.to include(
        title_tesim: [work_version.title],
        latest_version_bsi: false,
        display_work_type_ssi: Work::Types.display(work_version.work_type),
        work_type_ss: work_version.work_type,
        published_date_dtrsi: '1999',
        embargoed_until_dtsi: nil,
        depositor_id_isi: work_version.work.depositor.id,
        proxy_id_isi: nil,
        discover_users_ssim: [],
        discover_groups_ssim: [Group::PUBLIC_AGENT_NAME],
        visibility_ssi: Permissions::Visibility::OPEN
      )
    end
  end

  describe '#perform_update_index' do
    let(:work_version) { described_class.new }

    before { allow(SolrIndexingJob).to receive(:perform_later) }

    it 'provides itself to SolrIndexingJob.perform_later' do
      work_version.send(:perform_update_index)
      expect(SolrIndexingJob).to have_received(:perform_later).with(work_version)
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

  describe '#publish' do
    let(:work_version) { build :work_version, :able_to_be_published }
    let(:work) { work_version.work }

    it "updates the work's deposit agreement" do
      expect(work.deposit_agreement_version).to be_nil
      expect(work.deposit_agreed_at).to be_nil
      work_version.publish
      work.reload
      expect(work.deposit_agreement_version).to eq(Work::DepositAgreement::CURRENT_VERSION)
      expect(work.deposit_agreed_at).to be_within(1.minute).of(Time.zone.now)
    end
  end

  describe '#force_destroy' do
    it { is_expected.to respond_to(:force_destroy).and respond_to(:force_destroy=) }
  end

  describe '#destroy' do
    context 'with a published version' do
      let(:work_version) { create(:work_version, :published) }

      context 'when force_destroy is false' do
        it 'raises an error' do
          expect {
            work_version.destroy
          }.to raise_error(ArgumentError, 'cannot delete published versions')
        end
      end

      context 'when force_destroy is true' do
        before { work_version.force_destroy = true } # get off my lawn

        it 'raises an error' do
          expect {
            work_version.destroy
          }.to change(described_class, :count).by(-1)
        end
      end
    end

    context 'with a draft version' do
      let!(:work_version) { create(:work_version, :draft) }

      it 'deletes the version' do
        expect {
          work_version.destroy
        }.to change(described_class, :count).by(-1)
      end
    end
  end

  describe WorkVersion::Licenses do
    let(:active_license) do
      {
        id: 'https://creativecommons.org/licenses/by/4.0/',
        label: 'Attribution 4.0 International (CC BY 4.0)',
        active: true
      }
    end

    let(:inactive_license) do
      {
        id: 'http://creativecommons.org/licenses/by/3.0/us/',
        label: 'Attribution 3.0 United States',
        active: false
      }
    end

    describe '::DEFAULT' do
      subject { described_class::DEFAULT }

      it { is_expected.to eq('http://www.europeana.eu/portal/rights/rr-r.html') }
    end

    describe '::all' do
      subject { described_class.all }

      it { is_expected.to include(inactive_license) }
      it { is_expected.to include(active_license) }
    end

    describe '::active' do
      subject { described_class.active }

      it { is_expected.not_to include(inactive_license) }
      it { is_expected.to include(active_license) }
    end

    describe '::options_for_select_box' do
      subject(:options) { described_class.options_for_select_box }

      specify do
        expect(options).to contain_exactly(
          [
            'Attribution 4.0 International (CC BY 4.0)',
            'https://creativecommons.org/licenses/by/4.0/'
          ],
          [
            'Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)',
            'https://creativecommons.org/licenses/by-sa/4.0/'
          ],
          [
            'Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)',
            'https://creativecommons.org/licenses/by-nc/4.0/'
          ],
          [
            'Attribution-NoDerivatives 4.0 International (CC BY-ND 4.0)',
            'https://creativecommons.org/licenses/by-nd/4.0/'
          ],
          [
            'Attribution-NonCommercial-NoDerivatives 4.0 International (CC BY-NC-ND 4.0)',
            'https://creativecommons.org/licenses/by-nc-nd/4.0/'
          ],
          [
            'Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)',
            'https://creativecommons.org/licenses/by-nc-sa/4.0/'
          ],
          ['Public Domain Mark 1.0', 'http://creativecommons.org/publicdomain/mark/1.0/'],
          ['CC0 1.0 Universal', 'http://creativecommons.org/publicdomain/zero/1.0/'],
          ['All rights reserved', 'https://rightsstatements.org/page/InC/1.0/'],
          ['Apache 2.0', 'http://www.apache.org/licenses/LICENSE-2.0'],
          ['GNU General Public License (GPLv3)', 'https://www.gnu.org/licenses/gpl.html'],
          ['MIT License', 'https://opensource.org/licenses/MIT'],
          ['BSD 3-Clause License', 'https://opensource.org/licenses/BSD-3-Clause']
        )
      end
    end

    describe '::label' do
      subject { described_class.label(license['id']) }

      context 'with an existing id' do
        let(:license) { described_class.all.sample }

        it { is_expected.to eq(license['label']) }
      end

      context 'with an invalid id' do
        let(:license) { { 'id' => 'bogus' } }

        it { is_expected.to be_nil }
      end
    end
  end
end
