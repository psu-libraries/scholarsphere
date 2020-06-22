# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileResource, type: :model do
  it_behaves_like 'a resource with a deposited at timestamp'

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
        api_token: ApiToken.metadata_listener.token
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
end
