# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileResource, type: :model do
  it_behaves_like 'a resource with a deposited at timestamp'

  it_behaves_like 'a resource with view statistics' do
    let(:resource) { create(:file_resource) }
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
        api_token: ExternalApp.metadata_listener.token
      )
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
end
