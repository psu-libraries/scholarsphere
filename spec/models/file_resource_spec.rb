# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileResource, type: :model do
  it_behaves_like 'a resource with a deposited at timestamp'

  it_behaves_like 'a resource with view statistics' do
    let(:resource) { create(:file_resource) }
  end

  it_behaves_like 'a resource with a generated uuid' do
    let(:resource) { build(:file_resource) }
  end

  describe 'table' do
    it { is_expected.to have_db_column(:file_data).of_type(:jsonb) }
  end

  describe 'factories' do
    it { is_expected.to have_valid_factory(:file_resource) }
    it { is_expected.to have_valid_factory(:file_resource, :with_processed_image) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:file_version_memberships) }
    it { is_expected.to have_many(:work_versions).through(:file_version_memberships) }
    it { is_expected.to have_many(:view_statistics) }
    it { is_expected.to have_many(:legacy_identifiers) }
  end

  describe '::reindex_all' do
    before do
      create(:file_resource)
      allow(IndexingService).to receive(:commit)
      allow(SolrIndexingJob).to receive(:perform_now)
      allow(SolrIndexingJob).to receive(:perform_later)
    end

    context 'with defaults' do
      it 'reindexes all the files' do
        described_class.reindex_all
        expect(SolrIndexingJob).to have_received(:perform_now).once
        expect(IndexingService).to have_received(:commit).once
      end
    end

    context 'when async' do
      it 'reindexes all the files' do
        described_class.reindex_all(async: true)
        expect(SolrIndexingJob).to have_received(:perform_later).once
        expect(IndexingService).to have_received(:commit).once
      end
    end
  end

  describe '#save' do
    let(:file_resource) { described_class.new }
    let(:file) { File.open(File.join(fixture_path, 'image.png')) }
    let(:file_data) { { 'id' => file_resource.file_data['id'], 'storage' => file_resource.file_data['storage'] } }

    before { file_resource.file = file }

    it 'promotes the file to storage asynchronously' do
      allow(Shrine::PromotionJob).to receive(:perform_later)
      file_resource.save
      expect(Shrine::PromotionJob).to have_received(:perform_later).with(
        record: file_resource,
        file_data: file_data,
        name: 'file'
      )
    end

    it 'initiates a metadata listener job' do
      allow(MetadataListener::Job).to receive(:perform_later)
      file_resource.save
      expect(MetadataListener::Job).to have_received(:perform_later).with(
        path: "#{file_data['storage']}/#{file_data['id']}",
        endpoint: "http://#{Rails.application.routes.default_url_options[:host]}/api/v1/files/#{file_resource.id}",
        api_token: ExternalApp.metadata_listener.token,
        services: [:virus, :extracted_text]
      )
    end
  end

  describe 'after save' do
    let(:file_resource) { build(:file_resource) }

    # I've heard it's bad practice to mock the object under test, but I can't
    # think of a better way to do this without testing the contents of
    # perform_update_index twice.

    it 'calls #perform_update_index' do
      allow(file_resource).to receive(:perform_update_index)
      file_resource.save!
      expect(file_resource).to have_received(:perform_update_index)
    end
  end

  describe '#perform_update_index' do
    let(:file_resource) { described_class.new }

    before { allow(SolrIndexingJob).to receive(:perform_later) }

    it 'provides itself to SolrIndexingJob.perform_later' do
      file_resource.send(:perform_update_index)
      expect(SolrIndexingJob).to have_received(:perform_later).with(file_resource)
    end
  end

  describe '#file' do
    subject { file_resource.file }

    let(:file_resource) { build(:file_resource, :with_processed_image) }

    its(:virus) { is_expected.to be_nil }
    its(:size) { is_expected.to eq(63960) }
    its(:mime_type) { is_expected.to eq('image/png') }
    its(:original_filename) { is_expected.to eq('image.png') }
  end

  describe '#derivatives' do
    subject { file_resource.extracted_text }

    let(:file_resource) { build(:file_resource, :with_processed_image) }
    let(:sample_file) { FileHelpers.text_file }

    let(:upload) do
      FileHelpers.shrine_upload(file: sample_file, storage: Scholarsphere::ShrineConfig::DERIVATIVES_PREFIX)
    end

    let(:uploaded_file) do
      Shrine.uploaded_file(
        storage: Scholarsphere::ShrineConfig::DERIVATIVES_PREFIX,
        id: upload[:id],
        metadata: upload[:metadata]
      )
    end

    before do
      file_resource.file_attacher.merge_derivatives(text: uploaded_file)
    end

    it { is_expected.to eq(sample_file.read) }
  end

  describe '#etag' do
    subject { create(:file_resource) }

    before { allow(Aws::S3::Client).to receive(:new).and_return(client) }

    context 'when the file exists' do
      let(:client) do
        Aws::S3::Client.new(
          access_key_id: ENV['AWS_ACCESS_KEY_ID'],
          secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
          region: ENV['AWS_REGION'],
          endpoint: ENV['S3_ENDPOINT'],
          force_path_style: true
        )
      end

      its(:etag) { is_expected.to eq('33036b1bffe083c5d30824f1ff204b90') }
    end

    context 'when the file does NOT exist' do
      let(:client) { instance_spy('Aws::S3::Client') }
      let(:error) { Aws::S3::Errors::Forbidden.new('arg1', 'arg2') }

      before { allow(client).to receive(:head_object).with(any_args).and_raise(error) }

      its(:etag) { is_expected.to eq('[unavailable]') }
    end
  end

  describe '#to_solr' do
    subject { create(:file_resource).to_solr }

    let(:expected_keys) do
      %w(
        deposited_at_dtsi
        extracted_text_tei
        created_at_dtsi
        id
        model_ssi
        updated_at_dtsi
        uuid_ssi
      )
    end

    its(:keys) { is_expected.to contain_exactly(*expected_keys) }
  end

  describe '#update_index' do
    let(:file_resource) { build(:file_resource) }

    before { allow(IndexingService).to receive(:add_document) }

    context 'with defaults' do
      it 'calls the IndexingService' do
        file_resource.update_index
        expect(IndexingService).to have_received(:add_document).with(file_resource.to_solr, commit: true)
      end
    end

    context 'when specifing NOT to commit' do
      it 'calls the IndexingService and does not commit it to the index' do
        file_resource.update_index(commit: false)
        expect(IndexingService).to have_received(:add_document).with(file_resource.to_solr, commit: false)
      end
    end
  end
end
