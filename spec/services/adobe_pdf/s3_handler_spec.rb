# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdobePdf::S3Handler do
  describe '#download_file' do
    let(:dummy_class) { Class.new { include AdobePdf::S3Handler } }
    let(:instance) { dummy_class.new }

    it 'downloads the file from S3 and returns a Tempfile object' do
      resource = create :file_resource

      result = instance.download_file(resource)

      expect(result.class).to eq(Tempfile)
      expect(result.size).to be_positive
    end

    it 'raises an Aws::S3::Errors::ServiceError if the download fails' do
      # This key does not exist in S3
      resource = instance_double(FileResource, file_data: { 'id' => '123', 'storage' => 'store' })

      expect { instance.download_file(resource) }.to raise_error(Aws::S3::Errors::ServiceError)
    end
  end
end
