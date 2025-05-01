# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LegacyUrlsController, type: :request do
  describe 'Scholarsphere v3 legacy URLs to a Work/Version' do
    let(:resource) { create(:work_version) }

    before do
      create(:legacy_identifier,
             version: 3,
             old_id: 'old-v3-id-123',
             resource: resource)
    end

    it do
      get '/concern/generic_works/old-v3-id-123'
      expect(response).to redirect_to resource_path(resource.uuid)
    end

    context 'when given a nonexistent id' do
      it do
        get '/concern/generic_works/doesnt-exist'
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when given an ID to a scholarsphere-2 record' do
      before do
        create(:legacy_identifier,
               version: 2,
               old_id: 'old-v2-id-222',
               resource: resource)
      end

      it do
        get '/concern/generic_works/doesnt-exist'
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when directed from a v3 file download path' do
      before do
        create(:legacy_identifier,
               version: 3,
               old_id: 'old1234id',
               resource: resource)
      end

      it do
        get '/downloads/old1234id'
        expect(response).to redirect_to resource_path(resource.uuid)
      end
    end
  end

  describe 'Scholarsphere v3 legacy URLs to a Collection' do
    let(:resource) { create(:collection) }

    before do
      create(:legacy_identifier,
             version: 3,
             old_id: 'old-v3-id-456',
             resource: resource)
    end

    it do
      get '/collections/old-v3-id-456'
      expect(response).to redirect_to resource_path(resource.uuid)
    end
  end
end
