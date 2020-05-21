# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::RestController, type: :controller do
  # @note Create an anonymous controller to test the features of our base class
  controller do
    def index
      render plain: 'success'
    end
  end

  it { is_expected.not_to be_a(ApplicationController) }
  it { is_expected.to be_a(ActionController::API) }

  context 'with an unauthenticated request' do
    subject { response }

    context 'without providing an API token' do
      before { get :index }

      its(:status) { is_expected.to eq 401 }
      its(:body) { is_expected.to include(I18n.t('api.errors.not_authorized')) }
    end

    context 'when providing a bad token' do
      before do
        request.headers[:'X-API-Key'] = 'bad-token'
        get :index
      end

      its(:status) { is_expected.to eq 401 }
    end
  end

  context 'with an authenticated request' do
    subject { response }

    let!(:api_key) { create :api_token }

    before do
      request.headers[:'X-API-Key'] = api_key.token
      get :index
    end

    its(:status) { is_expected.to eq 200 }
    its(:body) { is_expected.to eq 'success' }
  end

  context 'when there is an unexpected error' do
    let!(:api_key) { create :api_token }

    before do
      allow(controller).to receive(:index).and_raise(NoMethodError, 'well, this is unexpected!')
      request.headers[:'X-API-Key'] = api_key.token
      get :index
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
