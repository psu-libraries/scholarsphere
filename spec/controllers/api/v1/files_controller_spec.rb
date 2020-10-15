# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::FilesController, type: :controller do
  let(:api_token) { create(:api_token).token }

  before { request.headers[:'X-API-Key'] = api_token }

  describe 'PATCH #update' do
    let(:file) { create(:file_resource) }
    let(:scan_time) { Time.zone.now.iso8601 }

    context 'with valid input' do
      before do
        patch :update, params: {
          id: file.id,
          metadata: { virus: { status: false, scanned_at: scan_time } }
        }
      end

      it "updates the file's metadata" do
        expect(response).to be_ok
        expect(file.reload.file_data['metadata']).to include(
          'virus' => { 'status' => 'false', 'scanned_at' => scan_time }
        )
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
