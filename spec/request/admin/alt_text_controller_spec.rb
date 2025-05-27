# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::AltTextController, type: :request do
  let(:file_resource) { create(:file_resource) }
  let(:alt_text) { 'A new alt text' }
  let(:params) { { file_resource: { alt_text: alt_text } } }

  describe 'PATCH /admin/alt_text/:id' do
    context 'when user is an admin' do
      let(:admin) { create(:user, :admin) }

      before { sign_in admin }

      context 'with valid params' do
        it 'updates the alt_text metadata and returns success JSON' do
          patch admin_update_alt_text_path(file_resource), params: params, as: :json

          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['success']).to eq(true)
          expect(json['alt_text']).to eq(alt_text)
          file_resource.reload
          expect(file_resource.file_data['metadata']['alt_text']).to eq(alt_text)
        end
      end

      context 'when the update fails' do
        let(:file_resource_double) { instance_double(FileResource,
                                                     save: false,
                                                     file_attacher: file_attacher_double,
                                                     file_data: { 'metadata' => { 'alt_text' => alt_text } }) }
        let(:file_attacher_double) { instance_double(FileUploader::Attacher) }
        let(:file_errors_double) { instance_double(ActiveModel::Errors,
                                                   full_messages: ['Something went wrong']) }

        before do
          allow(file_attacher_double).to receive(:add_metadata).with(alt_text: alt_text)
          allow(file_resource_double).to receive_messages(errors: file_errors_double,
                                                          reload: file_resource_double)
          allow(FileResource).to receive(:find).and_return(file_resource_double)
        end

        it 'returns an error JSON response' do
          patch admin_update_alt_text_path(file_resource), params: params, as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json['success']).to eq(false)
          expect(json['errors']).to eq(['Something went wrong'])
          expect(json['alt_text']).to eq(alt_text)
        end
      end
    end

    context 'when user is not an admin' do
      let(:user) { create(:user) }

      before { sign_in user }

      it 'returns not found' do
        patch admin_update_alt_text_path(file_resource), params: params, as: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when user is not signed in' do
      it 'returns unauthorized' do
        patch admin_update_alt_text_path(file_resource), params: params, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
