# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UpdateExtractedText do
  let(:resource) { FactoryBot.build(:file_resource, id: 1) }

  before do
    allow(MetadataListener::Job).to receive(:perform_later)
  end

  context 'when the file has no extracted text' do
    it 'updates the resource' do
      expect(resource.extracted_text).not_to be_present
      described_class.call(resource: resource)
      expect(MetadataListener::Job).to have_received(:perform_later).with(
        path: [resource.file_data['storage'], resource.file_data['id']].join('/'),
        endpoint: FileUploader.api_endpoint(resource),
        api_token: ExternalApp.metadata_listener.token,
        services: [:extracted_text]
      )
    end
  end

  context 'when the file has extracted text present' do
    before { allow(resource).to receive(:extracted_text).and_return('text') }

    it 'does NOT update the resource' do
      expect(resource.extracted_text).to be_present
      described_class.call(resource: resource)
      expect(MetadataListener::Job).not_to have_received(:perform_later)
    end
  end

  context 'when the file has extracted text and force is true' do
    before { allow(resource).to receive(:extracted_text).and_return('text') }

    it 'updates the resource' do
      expect(resource.extracted_text).to be_present
      described_class.call(resource: resource, force: true)
      expect(MetadataListener::Job).to have_received(:perform_later).with(
        path: [resource.file_data['storage'], resource.file_data['id']].join('/'),
        endpoint: FileUploader.api_endpoint(resource),
        api_token: ExternalApp.metadata_listener.token,
        services: [:extracted_text]
      )
    end
  end
end
