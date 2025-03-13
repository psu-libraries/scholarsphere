# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::FilesController do
  let(:api_token) { create(:api_token).token }

  before { request.headers[:'X-API-Key'] = api_token }

  describe 'PATCH #update' do
    let(:file) { create(:file_resource) }
    let(:scan_time) { Time.zone.now.iso8601 }
    let(:metadata) do
      {
        virus: { status: 'false', scanned_at: scan_time },
        fits: {
          foo: 'bar',
          crankstations: 'true'
        }
      }
    end

    def file_data
      ActiveSupport::HashWithIndifferentAccess.new(file.reload.file_data['metadata'])
    end

    context 'with valid input' do
      before do
        patch :update, params: {
          id: file.id,
          metadata: metadata
        }
      end

      it "updates the file's metadata" do
        expect(response).to be_ok
        expect(file_data).to include(metadata)
      end
    end

    context 'when updating existing metadata' do
      let(:updated_metadata) do
        {
          fits: {
            foo: 'baz',
            crankerstationer: 'false'
          }
        }
      end

      before do
        file.file_attacher.add_metadata(metadata)
        file.file_attacher.write
        file.save
      end

      it 'only updates the given values' do
        expect(file_data).to include(metadata)
        patch :update, params: { id: file.id, metadata: updated_metadata }
        expect(response).to be_ok
        expect(file_data).to include(updated_metadata)
        expect(file_data.dig('virus', 'status')).to eq('false')
        expect(file_data.dig('virus', 'scanned_at')).to eq(scan_time)
      end
    end

    context 'when adding derivatives' do
      let(:extracted_text_file) { FileHelpers.text_file }

      let(:upload) do
        FileHelpers.shrine_upload(file: extracted_text_file, storage: Scholarsphere::ShrineConfig::DERIVATIVES_PREFIX)
      end

      before do
        patch :update, params: {
          id: file.id,
          derivatives: {
            text: upload
          }
        }
      end

      it 'adds the extracted text file to the record' do
        expect(response).to be_ok
        file.reload
        expect(file.extracted_text).to eq(extracted_text_file.read)
      end
    end

    context 'when saving fails' do
      before do
        file.errors.add(:metadata, 'bad')
        allow(FileResource).to receive(:find).and_return(file)
        allow(file).to receive(:save).and_return(false)
        patch :update, params: {
          id: file.id,
          metadata: { virus: { status: false, scanned_at: scan_time } }
        }
      end

      it 'returns an error response' do
        expect(response.status).to eq(422)
        expect(response.body).to eq(
          '{"message":"Unable to complete the request","errors":["Metadata bad"]}'
        )
      end
    end
  end
end
