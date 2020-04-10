# frozen_string_literal: true

require 'rails_helper'

# @note While this is technically a controller test, because it's testing our REST API, we're really using it as a
# feature test to ensure end-to-end functionality of our ingest API.

RSpec.describe Api::V1::IngestController, type: :controller do
  let(:api_token) { create(:api_token).token }
  let(:user) { build(:actor) }
  let(:creator_alias) do
    {
      alias: "#{user.given_name} #{user.surname}",
      actor_attributes: {
        email: user.email,
        given_name: user.given_name,
        surname: user.surname,
        psu_id: user.psu_id
      }
    }
  end

  before { request.headers[:'X-API-Key'] = api_token }

  describe 'POST #create' do
    context 'with valid input' do
      before do
        post :create, params: {
          metadata: { title: FactoryBotHelpers.work_title, creator_aliases_attributes: [creator_alias] },
          depositor: { given_name: user.given_name, surname: user.surname, email: user.email, psu_id: user.psu_id },
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
          metadata: { title: FactoryBotHelpers.work_title, creator_aliases_attributes: [creator_alias] },
          content: [{ file: file.to_shrine.to_json }],
          depositor: { given_name: user.given_name, surname: user.surname, email: user.email, psu_id: user.psu_id }
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
        path = Pathname.new(fixture_path).join('image.png')
        file = Scholarsphere::S3::UploadedFile.new(path)
        post :create, params: {
          metadata: { title: FactoryBotHelpers.work_title },
          content: [{ file: file.to_shrine.to_json }]
        }
      end

      it 'reports the error with the missing parameter' do
        expect(response).to be_bad_request
        expect(response.body).to eq(
          '{"message":"Bad request","errors":["param is missing or the value is empty: depositor"]}'
        )
      end
    end

    context 'with missing metadata' do
      before do
        post :create, params: {
          metadata: { title: nil },
          depositor: { given_name: user.given_name, surname: user.surname, email: user.email, psu_id: user.psu_id },
          content: [{ file: fixture_file_upload(File.join(fixture_path, 'image.png')) }]
        }
      end

      it 'reports the error' do
        expect(response.status).to eq(422)
        expect(response.body).to eq(
          '{' \
            '"message":"Unable to complete the request",' \
            "\"errors\":[\"Versions title can't be blank\"]" \
          '}'
        )
      end
    end

    context 'with missing files' do
      before do
        post :create, params: {
          metadata: { title: FactoryBotHelpers.work_title, creator_aliases_attributes: [creator_alias] },
          depositor: { given_name: user.given_name, surname: user.surname, email: user.email, psu_id: user.psu_id }
        }
      end

      it 'saves the work with errors' do
        expect(response).to be_created
        expect(response.body).to eq(
          '{' \
            '"message":"Work was created but cannot be published",' \
            "\"errors\":[\"File resources can't be blank\"]" \
          '}'
        )
      end
    end

    context 'when the work cannot be published' do
      before do
        post :create, params: {
          metadata: { title: FactoryBotHelpers.work_title },
          depositor: { given_name: user.given_name, surname: user.surname, email: user.email, psu_id: user.psu_id },
          content: [{ file: fixture_file_upload(File.join(fixture_path, 'image.png')) }]
        }
      end

      it 'saves the work with errors' do
        expect(response).to be_created
        expect(response.body).to eq(
          '{' \
            '"message":"Work was created but cannot be published",' \
            "\"errors\":[\"Creator can't be blank\"]" \
          '}'
        )
      end
    end

    context 'when a work with the same noid already exists' do
      let(:legacy_identifier) { create(:legacy_identifier, :with_work, version: 3) }

      before do
        post :create, params: {
          metadata: { title: FactoryBotHelpers.work_title, noid: legacy_identifier.old_id },
          depositor: { given_name: user.given_name, surname: user.surname, email: user.email, psu_id: user.psu_id },
          content: [{ file: fixture_file_upload(File.join(fixture_path, 'image.png')) }]
        }
      end

      it 'returns the url of the previously migrated work' do
        expect(response.status).to eq(303)
        expect(response.body).to eq(
          "{\"message\":\"Work has already been migrated\",\"url\":\"/resources/#{legacy_identifier.resource.uuid}\"}"
        )
      end
    end

    context 'when there is an unexpected error' do
      before do
        allow(controller).to receive(:create).and_raise(NoMethodError, 'well, this is unexpected!')
        post :create, params: {
          metadata: { title: FactoryBotHelpers.work_title, creator_aliases_attributes: [creator_alias] },
          depositor: { given_name: user.given_name, surname: user.surname, email: user.email, psu_id: user.psu_id },
          content: [{ file: fixture_file_upload(File.join(fixture_path, 'image.png')) }]
        }
      end

      it 'reports the error' do
        expect(response.status).to eq(500)
        expect(response.body).to eq(
          '{' \
            "\"message\":\"We're sorry, but something went wrong\"," \
            '"errors":["NoMethodError","well, this is unexpected!"]' \
          '}'
        )
      end
    end
  end
end
