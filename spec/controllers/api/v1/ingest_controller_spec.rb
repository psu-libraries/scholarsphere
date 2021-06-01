# frozen_string_literal: true

require 'rails_helper'

# @note While this is technically a controller test, because it's testing our REST API, we're really using it as a
# feature test to ensure end-to-end functionality of our ingest API.

RSpec.describe Api::V1::IngestController, type: :controller do
  let(:api_token) { create(:api_token).token }
  let(:depositor) { VCRHelpers.depositor }
  let(:creator) do
    {
      display_name: attributes_for(:authorship)[:display_name]
    }
  end

  let(:metadata) { attributes_for(:work_version, :able_to_be_published) }

  let(:json_response) { HashWithIndifferentAccess.new(JSON.parse(response.body)) }

  before do
    request.headers[:'X-API-Key'] = api_token
  end

  describe 'POST #create' do
    context 'with valid input', vcr: VCRHelpers.depositor_cassette do
      before do
        post :create, params: {
          metadata: {
            title: metadata[:title],
            work_type: Work::Types.default,
            description: metadata[:description],
            published_date: metadata[:published_date],
            creators: [creator],
            rights: metadata[:rights],
            visibility: Permissions::Visibility::OPEN
          },
          depositor: depositor,
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

    context 'with a Penn State user', vcr: VCRHelpers.depositor_cassette do
      let(:creator) do
        {
          psu_id: depositor
        }
      end

      before do
        post :create, params: {
          metadata: {
            title: metadata[:title],
            work_type: Work::Types.default,
            description: metadata[:description],
            published_date: metadata[:published_date],
            creators: [creator],
            rights: metadata[:rights],
            visibility: Permissions::Visibility::OPEN
          },
          depositor: depositor,
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

    context 'with an Orcid id', :vcr do
      let(:creator) do
        {
          orcid: '0000-0002-8985-2378'
        }
      end

      before do
        post :create, params: {
          metadata: {
            title: metadata[:title],
            work_type: Work::Types.default,
            description: metadata[:description],
            published_date: metadata[:published_date],
            creators: [creator],
            rights: metadata[:rights],
            visibility: Permissions::Visibility::OPEN
          },
          depositor: depositor,
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

    context 'when uploading files from S3', vcr: VCRHelpers.depositor_cassette do
      let(:s3_file) do
        S3Helpers.shrine_upload(file: Pathname.new(fixture_path).join('image.png'))
      end

      before do
        post :create, params: {
          metadata: {
            title: metadata[:title],
            work_type: Work::Types.default,
            description: metadata[:description],
            published_date: metadata[:published_date],
            creators: [creator],
            rights: metadata[:rights],
            visibility: Permissions::Visibility::OPEN
          },
          content: [{ file: s3_file.to_json }],
          depositor: depositor
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
      let(:s3_file) do
        S3Helpers.shrine_upload(file: Pathname.new(fixture_path).join('image.png'))
      end

      before do
        post :create, params: {
          metadata: { title: FactoryBotHelpers.work_title },
          content: [{ file: s3_file.to_json }]
        }
      end

      it 'reports the error with the missing parameter' do
        expect(response).to be_bad_request
        expect(json_response['message']).to eq('Bad request')
        expect(json_response['errors']).to include(/param is missing or the value is empty: depositor/)
      end
    end

    context 'with missing metadata', vcr: VCRHelpers.depositor_cassette do
      before do
        post :create, params: {
          metadata: { title: nil },
          depositor: depositor,
          content: [{ file: fixture_file_upload(File.join(fixture_path, 'image.png')) }]
        }
      end

      it 'reports the error' do
        expect(response.status).to eq(422)
        expect(json_response[:message]).to eq('Unable to complete the request')
        expect(json_response[:errors]).to include(
          "Versions title can't be blank"
        )
      end
    end

    context 'with missing files', vcr: VCRHelpers.depositor_cassette do
      before do
        post :create, params: {
          metadata: {
            title: metadata[:title],
            description: metadata[:description],
            published_date: metadata[:published_date],
            creators: [creator]
          },
          depositor: depositor
        }
      end

      it 'reports the error' do
        expect(response.status).to eq(422)
        expect(json_response[:message]).to eq('Unable to complete the request')
        expect(json_response[:errors]).to include(
          "Versions file resources can't be blank"
        )
      end
    end

    context 'with missing creators', vcr: VCRHelpers.depositor_cassette do
      before do
        post :create, params: {
          metadata: {
            title: metadata[:title],
            description: metadata[:description],
            published_date: metadata[:published_date]
          },
          depositor: depositor,
          content: [{ file: fixture_file_upload(File.join(fixture_path, 'image.png')) }]
        }
      end

      it 'reports the error' do
        expect(response.status).to eq(422)
        expect(json_response[:message]).to eq('Unable to complete the request')
        expect(json_response[:errors]).to include(
          "Versions creators can't be blank"
        )
      end
    end

    context 'when the depositor does not exist', :vcr do
      before do
        post :create, params: {
          metadata: {
            title: metadata[:title],
            work_type: Work::Types.default,
            description: metadata[:description],
            published_date: metadata[:published_date],
            creators: [creator],
            rights: metadata[:rights],
            visibility: Permissions::Visibility::OPEN
          },
          depositor: 'unknown',
          content: [{ file: fixture_file_upload(File.join(fixture_path, 'image.png')) }]
        }
      end

      it 'reports the error' do
        expect(response.status).to eq(422)
        expect(json_response[:message]).to eq('Unable to complete the request')
        expect(json_response[:errors]).to include(
          "Depositor 'unknown' does not exist"
        )
      end
    end
  end

  def i18n_error_message(attr, validation)
    wv = WorkVersion.new
    wv.errors.full_message(
      attr,
      wv.errors.generate_message(attr, validation)
    )
  end
end
