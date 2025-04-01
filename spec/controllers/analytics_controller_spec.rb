# frozen_string_literal: true

require 'rails_helper'

# @note While this is technically a controller test, because it's testing our
# REST API, we're really using it as a feature/request test

RSpec.describe AnalyticsController do
  let(:parsed_body) { response.parsed_body }

  describe 'GET #show' do
    context 'with a work version' do
      let(:resource) { instance_double('Collection', uuid: 'abc-123') }

      before do
        allow(FindResource).to receive(:call).with(resource.uuid).and_return(resource)

        allow(resource)
          .to receive(:stats)
          .and_return(
            [
              [Date.parse('2020-06-01'), 1, 1],
              [Date.parse('2020-06-02'), 2, 3]
            ]
          )
      end

      it 'returns the view counts as json' do
        get(:show, params: { resource_id: resource.uuid, format: :json })
        expect(resource).to have_received(:stats)

        expect(response).to be_ok
        expect(parsed_body).to eq [
          ['2020-06-01', 1, 1],
          ['2020-06-02', 2, 3]
        ]
      end

      context 'when the format is not json' do
        subject { response }

        before { get(:show, params: { resource_id: resource.uuid }) }

        it { is_expected.to have_http_status(:unsupported_media_type) }
      end
    end

    context "when the requested resource can't be found" do
      before { get(:show, params: { resource_id: 'not-a-resource' }) }

      specify { expect(response).to have_http_status(:not_found) }
    end
  end
end
