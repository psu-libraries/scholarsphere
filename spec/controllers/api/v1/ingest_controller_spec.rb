# frozen_string_literal: true

require 'rails_helper'

# @note While this is technically a controller test, because it's testing our REST API, we're really using it as a
# feature test to ensure end-to-end functionality of our ingest API.

RSpec.describe Api::V1::IngestController, type: :controller do
  let(:user) { create(:user) }

  describe 'POST #create' do
    context 'with valid input' do
      before do
        post :create, params: {
          metadata: { title: FactoryBotHelpers.work_title },
          depositor: user.access_id,
          content: [{ file: fixture_file_upload(File.join(fixture_path, 'image.png')) }]
        }
      end

      it 'publishes a new work' do
        expect(response).to be_ok
        expect(response.body).to eq(
          "{\"message\":\"Work was successfully created\",\"url\":\"/resources/#{Work.last.uuid}\"}"
        )
      end
    end

    context 'when uploading files from S3' do
      before do
        path = Pathname.new(fixture_path).join('image.png')
        file = Scholarsphere::S3::UploadedFile.new(path)
        Scholarsphere::S3::Uploader.new.upload(file)
        post :create, params: {
          metadata: { title: FactoryBotHelpers.work_title },
          content: [{ file: file.to_shrine.to_json }],
          depositor: user.access_id
        }
      end

      it 'publishes a new work' do
        expect(response).to be_ok
        expect(response.body).to eq(
          "{\"message\":\"Work was successfully created\",\"url\":\"/resources/#{Work.last.uuid}\"}"
        )
      end
    end

    context 'with missing parameters' do
      before do
        post :create, params: {
          metadata: { title: FactoryBotHelpers.work_title },
          depositor: user.access_id
        }
      end

      it 'reports the error with the missing parameter' do
        expect(response).to be_bad_request
        expect(response.body).to eq(
          '{"message":"Bad request","errors":["param is missing or the value is empty: content"]}'
        )
      end
    end

    context 'with missing metadata' do
      before do
        post :create, params: {
          metadata: { title: nil },
          depositor: user.access_id,
          content: [{ file: fixture_file_upload(File.join(fixture_path, 'image.png')) }]
        }
      end

      it 'reports the error' do
        expect(response.status).to eq(422)
        expect(response.body).to eq(
          "{\"message\":\"Unable to complete the request\",\"errors\":[\"Versions title can't be blank\"]}"
        )
      end
    end
  end
end
