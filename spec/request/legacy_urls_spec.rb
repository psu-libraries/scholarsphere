# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LegacyUrlsController, type: :request do
  let(:resource) { create :work_version }

  describe 'Scholarsphere v3 legacy URLs' do
    before do
      create :legacy_identifier,
             version: 3,
             old_id: 'old-v3-id-123',
             resource: resource
    end

    it do
      get '/concern/generic_works/old-v3-id-123'
      expect(response).to redirect_to resource_path(resource.uuid)
    end

    context 'when given a nonexistent id' do
      it do
        expect {
          get '/concern/generic_works/doesnt-exist'
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when given an ID to a scholarsphere-2 record' do
      before do
        create :legacy_identifier,
               version: 2,
               old_id: 'old-v2-id-222',
               resource: resource
      end

      it do
        expect {
          get '/concern/generic_works/doesnt-exist'
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
