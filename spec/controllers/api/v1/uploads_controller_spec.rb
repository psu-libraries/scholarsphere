# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::UploadsController, type: :controller do
  let(:api_token) { create(:api_token).token }

  before { request.headers[:'X-API-Key'] = api_token }

  describe 'POST #create' do
    let(:presigned_url) { JSON.parse(response.body)['url'] }
    let(:id) { JSON.parse(response.body)['id'] }
    let(:prefix) { JSON.parse(response.body)['prefix'] }

    let(:checksum) { 'md5sum' }

    before { post :create, params: { extension: extension, content_md5: checksum } }

    context 'with a valid extension' do
      let(:extension) { Faker::File.extension }

      it 'creates a presigned url' do
        expect(response).to be_ok
        expect(presigned_url).to include(ENV.fetch('S3_ENDPOINT', nil))
        expect(presigned_url).to include('content-md5')
        expect(URI.parse(presigned_url).path).to match(
          "/#{ENV.fetch('AWS_BUCKET', nil)}/#{Scholarsphere::ShrineConfig::CACHE_PREFIX}.*#{extension}"
        )
        expect(id).to end_with(extension)
        expect(prefix).to eq(Scholarsphere::ShrineConfig::CACHE_PREFIX)
      end
    end

    context 'when the extension includes the period' do
      let(:extension) { ".#{Faker::File.extension}" }

      it 'creates a presigned url without the duplicate period' do
        expect(response).to be_ok
        expect(URI.parse(presigned_url).path).not_to include('..')
        expect(id).not_to include('..')
      end
    end

    context 'with a missing key' do
      let(:extension) { nil }

      it { expect(response).to be_bad_request }
    end

    context 'without a checksum' do
      let(:extension) { Faker::File.extension }
      let(:checksum) { nil }

      it { expect(response).to be_bad_request }
    end
  end
end
