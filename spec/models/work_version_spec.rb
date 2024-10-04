# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkVersion, type: :model do
  it_behaves_like 'a resource with view statistics' do
    let(:resource) { create(:work_version) }
  end

  it_behaves_like 'a resource with a generated uuid' do
    let(:resource) { build(:work_version) }
  end

  it_behaves_like 'a resource that can provide all DOIs in', [:doi, :identifier]

  describe 'table' do
    it { is_expected.to have_db_column(:work_id) }
    it { is_expected.to have_db_index(:work_id) }
    it { is_expected.to have_db_column(:aasm_state) }
    it { is_expected.to have_db_column(:metadata).of_type(:jsonb) }
    it { is_expected.to have_db_column(:version_number).of_type(:integer) }
    it { is_expected.to have_db_column(:doi).of_type(:string) }
    it { is_expected.to have_db_column(:external_app_id) }
    it { is_expected.to have_db_column(:published_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:withdrawn_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:removed_at).of_type(:datetime) }
    it { is_expected.to have_jsonb_accessor(:title).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:subtitle).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:version_name).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:keyword).of_type(:string).is_array.with_default([]) }
    it { is_expected.to have_jsonb_accessor(:rights).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:description).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:publisher_statement).of_type(:string) }
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
    it { is_expected.to have_jsonb_accessor(:sub_work_type).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:program).of_type(:string) }
    it { is_expected.to have_jsonb_accessor(:degree).of_type(:string) }
  end

  describe 'factory' do
    it { is_expected.to have_valid_factory(:work_version) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:work) }
    it { is_expected.to belong_to(:external_app).optional(true) }
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

    describe '#file_version_memberships' do
      let(:resource) { create(:work_version, :with_files, file_count: 2) }

      it 'orders the files by title in ascending order' do
        n1 = (resource.file_version_memberships[0].title.match /image-(\d+).png/)[1].to_i
        n2 = n1 + 1

        expect(resource.file_version_memberships.map(&:title)).to eq(["image-#{n1}.png", "image-#{n2}.png"])

        resource.file_version_memberships[0].update(title: 'z.png')
        resource.file_version_memberships[1].update(title: 'a.png')

        resource.file_version_memberships.reload

        expect(resource.file_version_memberships.map(&:title)).to eq(['a.png', 'z.png'])
      end
    end
  end

  describe 'states' do
    subject(:work_version) { build(:work_version, work: work) }

    let(:work) { build(:work) }

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

      it 'validates that there are not duplicate embargo errors' do
        work_version.work.embargoed_until = 5.years.from_now
        work_version.save
        work_version.save
        expect(work_version.errors[:'work.embargoed_until']).to eq(['maximum is four years'])
        expect(work_version.errors[:'work.versions.work.embargoed_until']).to be_empty
      end

      context 'when visibility is set to AUTHORIZED' do
        before do
          work_version.work.access_controls.destroy_all
          work_version.work.grant_authorized_access
        end

        context 'when the validation context is `:user_publish`' do
          let(:valid_licenses) { described_class::Licenses.ids_for_authorized_visibility }
          let(:invalid_licenses) { described_class::Licenses.ids - valid_licenses }

          it 'requires #rights to be in WorkVersion::Licenses::ids_for_authorized_visibility' do
            expect(work_version).to(
              validate_inclusion_of(:rights)
              .in_array(valid_licenses)
              .on(:user_publish)
              .with_message(:incompatible_license_for_authorized_visibility)
            )

            invalid_licenses.each do |invalid_license|
              expect(work_version).not_to(
                allow_value(invalid_license)
                .for(:rights)
                .on(:user_publish)
              )
            end
          end
        end

        context 'when the validation context is something other than `:user_publish`' do
          let(:valid_licenses) { described_class::Licenses.ids }

          it 'allows #rights to be any value in WorkVersion::Licenses::ids' do
            expect(work_version).to validate_inclusion_of(:rights).in_array(valid_licenses)
          end
        end
      end

      context 'when publishing an identical work version' do
        subject(:work_version) { BuildNewWorkVersion.call(work.versions[0]) }

        let(:work) { create(:work, has_draft: false) }

        it 'validates if the new version is identical to the previous one' do
          work_version.validate
          expect(work_version.errors[:work_version]).to eq(['is the same as the previous version'])
        end
      end

      context 'when publishing an identical third work version' do
        subject(:work_version) { BuildNewWorkVersion.call(work.versions[1]) }

        let(:work) { create(:work, has_draft: false, versions_count: 2) }

        it 'validates if the new version is identical to the previous one' do
          work_version.validate
          expect(work_version.errors[:work_version]).to eq(['is the same as the previous version'])
        end
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
    it_behaves_like 'a singlevalued json field', :publisher_statement
    it_behaves_like 'a singlevalued json field', :published_date
    it_behaves_like 'a singlevalued json field', :rights
    it_behaves_like 'a singlevalued json field', :subtitle
    it_behaves_like 'a singlevalued json field', :version_name
  end

  it { is_expected.to delegate_method(:deposited_at).to(:work) }
  it { is_expected.to delegate_method(:depositor).to(:work) }
  it { is_expected.to delegate_method(:embargoed?).to(:work) }
  it { is_expected.to delegate_method(:embargoed_until).to(:work) }
  it { is_expected.to delegate_method(:proxy_depositor).to(:work) }
  it { is_expected.to delegate_method(:work_type).to(:work) }
  it { is_expected.to delegate_method(:thumbnail_url).to(:work) }

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
    subject(:work_version) { create(:work_version, :with_files, published_date: '1999-uu-uu') }

    before { work_version.file_resources.reload }

    its(:to_solr) do
      is_expected.to include(
        depositor_id_isi: work_version.work.depositor.id,
        discover_groups_ssim: [Group::PUBLIC_AGENT_NAME],
        discover_users_ssim: [],
        display_work_type_ssi: Work::Types.display(work_version.work_type),
        embargoed_until_dtsi: nil,
        file_resource_ids_ssim: [work_version.file_resources.first.uuid],
        file_version_titles_ssim: [work_version.file_version_memberships.first.title],
        latest_version_bsi: false,
        proxy_id_isi: nil,
        published_date_dtrsi: '1999',
        title_ssort: kind_of(String),
        title_tesim: [work_version.title],
        visibility_ssi: Permissions::Visibility::OPEN,
        work_type_ss: work_version.work_type
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

  describe '#perform_update_doi' do
    before { allow(DoiUpdatingJob).to receive(:perform_later) }

    context 'when the doi is not flagged for update' do
      let(:work_version) { build(:work_version, :published) }

      it 'does not send anything to DataCite' do
        work_version.save
        expect(DoiUpdatingJob).not_to have_received(:perform_later)
      end
    end

    context 'when the version is published, the work has a Doi, and updated_doi is set to true' do
      let(:work_version) { build(:work_version, :published) }

      it 'updates the metadata with DataCite' do
        work_version.work.doi = FactoryBotHelpers.datacite_doi
        work_version.update_doi = true
        work_version.save
        expect(DoiUpdatingJob).to have_received(:perform_later)
      end
    end

    context 'when the version is published and the work does not have a Doi' do
      let(:work_version) { build(:work_version, :published) }

      it 'does NOT send any updates to DataCite' do
        work_version.work.doi = nil
        work_version.update_doi = true
        work_version.save
        expect(DoiUpdatingJob).not_to have_received(:perform_later)
      end
    end
  end

  describe '#update_index' do
    let(:work_version) { described_class.new }

    before do
      allow(WorkIndexer).to receive(:call)
    end

    it 'calls the WorkIndexer' do
      work_version.update_index
      expect(WorkIndexer).to have_received(:call)
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

    it 'updates the published_at timestamp' do
      work_version.save
      expect(work_version.published_at).to be_nil
      work_version.publish!
      expect(work_version).to be_published
      expect(work_version.reload.published_at).to be_present.and be_within(1.second).of(Time.zone.now)
    end
  end

  context 'with a masters_culminating_experience work type' do
    let(:work_version) { create :work_version, :grad_culminating_experience_able_to_be_published }

    it 'sets the publisher to ScholarSphere automatically' do
      work_version.save
      expect(work_version.publisher).to eq []
      work_version.publish!
      expect(work_version).to be_published
      expect(work_version.reload.publisher).to eq ['ScholarSphere']
    end
  end

  context 'with a professional_doctoral_culminating_experience work type' do
    let(:work_version) { create :work_version, :grad_culminating_experience_able_to_be_published,
                                work: build(:work, work_type: 'professional_doctoral_culminating_experience') }

    it 'sets the publisher to ScholarSphere automatically' do
      work_version.save
      expect(work_version.publisher).to eq []
      work_version.publish!
      expect(work_version).to be_published
      expect(work_version.reload.publisher).to eq ['ScholarSphere']
    end
  end

  context 'with a work that is not a masters_culminating_experience or a professional_doctoral_culminating_experience' do
    let(:work_version) { create :work_version, :able_to_be_published, work: build(:work, work_type: 'article') }

    it 'does not edit the publisher field' do
      work_version.save
      expect(work_version.publisher).to eq []
      work_version.publish!
      expect(work_version).to be_published
      expect(work_version.reload.publisher).to eq []
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
        label: 'CC BY 4.0 (Attribution)',
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

      it { is_expected.to eq('https://rightsstatements.org/page/InC/1.0/') }
    end

    describe '::ids_for_authorized_visibility' do
      subject { described_class.ids_for_authorized_visibility }

      it { is_expected.to contain_exactly('https://rightsstatements.org/page/InC/1.0/') }
    end

    describe '::all' do
      subject { described_class.all }

      it { is_expected.to include(inactive_license) }
      it { is_expected.to include(active_license) }
      it { is_expected.to include(hash_including(id: described_class::DEFAULT)) }
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
            'CC BY 4.0 (Attribution)',
            'https://creativecommons.org/licenses/by/4.0/'
          ],
          [
            'CC BY-SA 4.0 (Attribution-ShareAlike)',
            'https://creativecommons.org/licenses/by-sa/4.0/'
          ],
          [
            'CC BY-NC 4.0 (Attribution-NonCommercial)',
            'https://creativecommons.org/licenses/by-nc/4.0/'
          ],
          [
            'CC BY-ND 4.0 (Attribution-NoDerivatives)',
            'https://creativecommons.org/licenses/by-nd/4.0/'
          ],
          [
            'CC BY-NC-ND 4.0 (Attribution-NonCommercial-NoDerivatives)',
            'https://creativecommons.org/licenses/by-nc-nd/4.0/'
          ],
          [
            'CC BY-NC-SA 4.0 (Attribution-NonCommercial-ShareAlike)',
            'https://creativecommons.org/licenses/by-nc-sa/4.0/'
          ],
          ['CC0 1.0 (Public Domain Dedication)', 'http://creativecommons.org/publicdomain/zero/1.0/'],
          ['MIT License', 'https://opensource.org/licenses/MIT'],
          ['BSD 3-Clause License', 'https://opensource.org/licenses/BSD-3-Clause'],
          ['Apache 2.0', 'http://www.apache.org/licenses/LICENSE-2.0'],
          ['GNU General Public License (GPLv3)', 'https://www.gnu.org/licenses/gpl.html'],
          ['In Copyright (Rights Reserved)', 'https://rightsstatements.org/page/InC/1.0/'],
          ['No Copyright - U.S.', 'https://rightsstatements.org/page/NoC-US/1.0/']
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

  describe '#set_thumbnail_selection' do
    context 'when associated work does not have any published versions' do
      let(:work) { create :work, has_draft: true }

      before do
        work.versions.last.file_resources << (create :file_resource)
        work.versions.last.save
      end

      context 'when the work_version has a file_resource with a thumbnail_url' do
        it "updates the work's thumbnail_selection to #{ThumbnailSelections::AUTO_GENERATED}" do
          allow_any_instance_of(FileResource).to receive(:thumbnail_url).and_return 'url.com/path/file'
          expect { work.versions.last.set_thumbnail_selection }
            .to change { work.reload.thumbnail_selection }.to ThumbnailSelections::AUTO_GENERATED
        end
      end

      context 'when the work_version has a file_resource without a thumbnail_url' do
        it "doesn't update the work's thumbnail_selection" do
          allow_any_instance_of(FileResource).to receive(:thumbnail_url).and_return nil
          expect { work.versions.last.set_thumbnail_selection }.not_to(change { work.reload.thumbnail_selection })
        end
      end
    end

    context 'when associated work does have a published version' do
      let(:work) { create :work, versions_count: 1, has_draft: false }

      before do
        work.versions.last.file_resources << (create :file_resource)
        work.versions.last.save
      end

      it "doesn't update the work's thumbnail_selection" do
        allow_any_instance_of(FileResource).to receive(:thumbnail_url).and_return 'url.com/path/file'
        expect { work.versions.last.set_thumbnail_selection }.not_to(change { work.reload.thumbnail_selection })
      end
    end
  end

  describe '#initial_draft?' do
    subject { work.versions.last }

    context 'when work version has one version that is a draft' do
      let(:work) { create(:work, has_draft: true, versions_count: 1) }

      it { is_expected.to be_initial_draft }
    end

    context 'when work version is has one version that is not a draft' do
      let(:work) { create(:work, has_draft: false, versions_count: 1) }

      it { is_expected.not_to be_initial_draft }
    end

    context 'when work version has more than one version including a draft' do
      let(:work) { create(:work, has_draft: true, versions_count: 2) }

      it { is_expected.not_to be_initial_draft }
    end

    context 'when work version has more than one version with no draft' do
      let(:work) { create(:work, has_draft: false, versions_count: 2) }

      it { is_expected.not_to be_initial_draft }
    end

    context 'when work version is temporarily published draft' do
      let(:work_version) { subject }

      before do
        work_version.aasm.from_state == :draft
        work_version.aasm.to_state == :published
      end

      context 'when work has one version' do
        let(:work) { create(:work, has_draft: true, versions_count: 1) }

        it { is_expected.to be_initial_draft }
      end

      context 'when work has more than one versions' do
        let(:work) { create(:work, has_draft: true, versions_count: 2) }

        it { is_expected.not_to be_initial_draft }
      end
    end
  end

  describe '#submission_link' do
    let(:work_version) { create(:work_version, uuid: '8d7eb165-25e0-4b60-8c94-8dc63ae6989f') }
    let(:expected_link) { 'https://scholarsphere.psu.edu/resources/8d7eb165-25e0-4b60-8c94-8dc63ae6989f' }

    it 'returns a link to the work' do
      expect(work_version.submission_link).to eq expected_link
    end
  end

  describe '#depositor_access_id' do
    let(:work_version) { create(:work_version) }
    let(:depositor) { build(:actor, psu_id: 'abc1234') }
    let(:work) { build(:work, versions: [work_version]) }

    it 'returns depositor access id' do
      depositor.deposited_works << [work]
      expect(work_version.depositor_access_id).to eq('abc1234')
    end
  end

  describe '#depositor_name' do
    let(:work_version) { create(:work_version) }
    let(:depositor) { build(:actor, display_name: 'Test Depositor') }
    let(:work) { build(:work, versions: [work_version]) }

    it 'returns depositor display name' do
      depositor.deposited_works << [work]
      expect(work_version.depositor_name).to eq('Test Depositor')
    end
  end

  describe '#form_partial' do
    let(:wv) { described_class.new }

    it 'returns work_version' do
      expect(wv.form_partial).to eq 'work_version'
    end
  end

  describe '#has_publisher_doi?' do
    let(:wv) { described_class.new(identifier: identifier) }
    let(:invalid_doi) { instance_double Doi, valid?: false }
    let(:valid_doi) { instance_double Doi, valid?: true }

    before do
      allow(Doi).to receive(:new).with('invalid DOI').and_return invalid_doi
      allow(Doi).to receive(:new).with('valid DOI').and_return valid_doi
    end

    context 'when the work version has no identifiers' do
      let(:identifier) { [] }

      it 'returns false' do
        expect(wv.has_publisher_doi?).to eq false
      end
    end

    context 'when the work version has an identifier value that is a valid DOI' do
      let(:identifier) { ['valid DOI'] }

      it 'returns true' do
        expect(wv.has_publisher_doi?).to eq true
      end
    end

    context 'when the work version has an identifier value that is not a valid DOI' do
      let(:identifier) { ['invalid DOI'] }

      it 'returns false' do
        expect(wv.has_publisher_doi?).to eq false
      end
    end

    context 'when the work version has identifier values that include both valid and invalid DOIs' do
      let(:identifier) { ['invalid DOI', 'valid DOI'] }

      it 'returns true' do
        expect(wv.has_publisher_doi?).to eq true
      end
    end
  end
end
