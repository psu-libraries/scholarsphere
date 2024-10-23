# frozen_string_literal: true

require 'rails_helper'
require 'aws-sdk-s3'

RSpec.describe AdobePdf::S3Handler, type: :service do
  let(:dummy_class) { Class.new { extend AdobePdf::S3Handler } }
  let(:resource) do
    double('FileResource', file_data: { 'id' => 'test-file-id', 'storage' => 'test-storage' })
  end
  let(:tempfile) { Tempfile.new('test-file-id') }
  let(:s3_client) { instance_double(Aws::S3::Client) }

  before do
    allow(dummy_class).to receive(:s3_client).and_return(s3_client)
    allow(dummy_class).to receive(:aws_bucket).and_return('test-bucket')
    allow(Tempfile).to receive(:new).and_return(tempfile)
  end

  describe '#download_file' do
    it 'downloads a file from S3 and returns a Tempfile object' do
      # Arrange
      allow(s3_client).to receive(:get_object).with(
        bucket: 'test-bucket',
        key: 'test-storage/test-file-id',
        response_target: tempfile.path
      )

      # Act
      result = dummy_class.download_file(resource)

      # Assert
      expect(result).to be_a(Tempfile)
      expect(result.path).to eq(tempfile.path)
    end

    it 'raises an error if the download fails' do
      # Arrange
      allow(s3_client).to receive(:get_object).and_raise(Aws::S3::Errors::ServiceError.new(nil, 'error'))

      # Act & Assert
      expect { dummy_class.download_file(resource) }.to raise_error(Aws::S3::Errors::ServiceError)
    end
  end

  describe '#s3_client' do
    it 'returns an instance of Aws::S3::Client' do
      # Act
      client = dummy_class.send(:s3_client)

      # Assert
      expect(client).to be_an_instance_of(Aws::S3::Client)
    end
  end

  describe '#aws_bucket' do
    it 'returns the AWS bucket name from the environment' do
      # Act
      bucket = dummy_class.send(:aws_bucket)

      # Assert
      expect(bucket).to eq('test-bucket')
    end
  end

  describe '#s3_options' do
    it 'returns the correct S3 options' do
      # Arrange
      allow(ENV).to receive(:fetch).with('AWS_ACCESS_KEY_ID', nil).and_return('test-access-key-id')
      allow(ENV).to receive(:fetch).with('AWS_SECRET_ACCESS_KEY', nil).and_return('test-secret-access-key')
      allow(ENV).to receive(:fetch).with('AWS_REGION', 'us-east-1').and_return('us-east-1')

      # Act
      options = dummy_class.send(:s3_options)

      # Assert
      expect(options).to include(
        access_key_id: 'test-access-key-id',
        secret_access_key: 'test-secret-access-key',
        region: 'us-east-1'
      )
    end

    it 'includes endpoint and force_path_style if S3_ENDPOINT is set' do
      # Arrange
      allow(ENV).to receive(:key?).with('S3_ENDPOINT').and_return(true)
      allow(ENV).to receive(:fetch).with('S3_ENDPOINT').and_return('http://localhost:9000')

      # Act
      options = dummy_class.send(:s3_options)

      # Assert
      expect(options).to include(
        endpoint: 'http://localhost:9000',
        force_path_style: true
      )
    end
  end
end
