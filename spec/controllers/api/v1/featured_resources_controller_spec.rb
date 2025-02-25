# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::FeaturedResourcesController do
  let(:api_token) { create(:api_token).token }

  before { request.headers[:'X-API-Key'] = api_token }

  describe 'POST #create' do
    subject { response }

    let(:work) { create(:work, has_draft: false) }

    context 'when creating a new featured resource' do
      before do
        post :create, params: { uuid: work.uuid }
      end

      it { is_expected.to be_created }
    end

    context 'when updating an existing featured resource' do
      before do
        FeaturedResource.create(resource: work, resource_uuid: work.uuid)
        post :create, params: { uuid: work.uuid }
      end

      it { is_expected.to be_ok }
    end

    context 'when the uuid does not exist' do
      before do
        post :create, params: { uuid: SecureRandom.uuid }
      end

      it { is_expected.to be_not_found }
    end
  end
end
