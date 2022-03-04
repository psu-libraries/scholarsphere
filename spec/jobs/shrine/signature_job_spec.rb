# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Shrine::SignatureJob, type: :job do
  let(:work_version) { create :work_version, :draft, :with_files }
  let(:record) { build(:file_resource) }
  let(:name) { 'file' }
  let(:file_data) { { id: SecureRandom.uuid, storage: 'cache' } }

  context 'with valid input' do
    it 'calculates a file signature' do
      file_resource = work_version.file_resources.first
      described_class.perform_now(file_resource_id: file_resource.id)
      expect(record.file.metadata['md5']).to eq('33036b1bffe083c5d30824f1ff204b90')
      expect(record.file.metadata['sha256']).to eq('86e19ad8675d5a83aabb8b8296b4092bb604c7ba0e853db6a7fcaf4e6e297df7')
    end
  end
end
