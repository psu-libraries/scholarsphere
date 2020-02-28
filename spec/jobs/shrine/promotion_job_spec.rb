# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Shrine::PromotionJob, type: :job do
  let(:record) { build(:file_resource) }
  let(:name) { 'file' }
  let(:file_data) { { id: SecureRandom.uuid, storage: 'cache' } }

  context 'with valid input' do
    let(:mock_attacher) { instance_spy(FileUploader::Attacher) }

    before { allow(Shrine::Attacher).to receive(:retrieve).and_return(mock_attacher) }

    it 'promotes a file from cache to storage' do
      described_class.perform_now(record: record, name: name, file_data: file_data)
      expect(mock_attacher).to have_received(:atomic_promote)
    end
  end

  context 'when the attachment has changed' do
    before { allow(Shrine::Attacher).to receive(:retrieve).and_raise(Shrine::AttachmentChanged) }

    it 'returns nil' do
      expect(described_class.perform_now(record: record, name: name, file_data: file_data)).to be_nil
    end
  end

  context 'when the record is not found' do
    before { allow(Shrine::Attacher).to receive(:retrieve).and_raise(ActiveRecord::RecordNotFound) }

    it 'returns nil' do
      expect(described_class.perform_now(record: record, name: name, file_data: file_data)).to be_nil
    end
  end

  context 'when an unexpected error occurs' do
    before { allow(Shrine::Attacher).to receive(:retrieve).and_raise(StandardError) }

    it 'returns nil' do
      expect {
        described_class.perform_now(record: record, name: name, file_data: file_data)
      }.to raise_error(StandardError)
    end
  end
end
