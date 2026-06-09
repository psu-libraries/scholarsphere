# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::Form::PublishController, type: :request do
  describe 'PATCH /dashboard/form/work_versions/:id/publish' do
    let(:work_version) { create(:work_version, remediated_version: false) }
    let(:request_params) do
      {
        work_version: {
          remediated_version: '1'
        },
        save_and_exit: '1'
      }
    end
    let!(:pdf_file) { create(:file_resource, :pdf, remediated_version: false) }
    let!(:non_pdf_file) { create(:file_resource, :readme_md, remediated_version: false) }

    before do
      create(:file_version_membership, work_version: work_version, file_resource: pdf_file)
      create(:file_version_membership, work_version: work_version, file_resource: non_pdf_file)
    end

    context 'when the current user is an admin' do
      let(:admin) { create(:user, :admin) }

      before { sign_in admin }

      it 'saves work_version.remediated_version and mirrors remediated_version to associated files' do
        expect(pdf_file.remediated_version).to be false
        expect(non_pdf_file.remediated_version).to be false

        patch dashboard_form_publish_path(work_version), params: request_params

        expect(response).to have_http_status(:redirect)
        expect(work_version.reload.remediated_version).to be true
        expect(pdf_file.reload.remediated_version).to be true
        expect(non_pdf_file.reload.remediated_version).to be true
      end
    end

    context 'when the current user is not an admin' do
      let(:user) { work_version.work.depositor.user }

      before { sign_in user }

      it 'does not mirror remediated_version to files (validation_context :user_publish)' do
        expect(pdf_file.remediated_version).to be false
        expect(non_pdf_file.remediated_version).to be false

        patch dashboard_form_publish_path(work_version), params: request_params

        expect(response).to have_http_status(:redirect)
        expect(pdf_file.reload.remediated_version).to be false
        expect(non_pdf_file.reload.remediated_version).to be false
      end
    end
  end

  describe 'webhook on publish' do
    let(:work_version) { create(:work_version, :able_to_be_published, open_access: open_access) }
    let(:open_access) { true }
    let(:user) { work_version.work.depositor.user }
    let(:request_params) do
      {
        publish: '1',
        work_version: {
          depositor_agreement: '1',
          psu_community_agreement: '1',
          accessibility_agreement: '1',
          sensitive_info_agreement: '1'
        }
      }
    end

    before do
      sign_in user
      allow(WorkPublishedWebhookJob).to receive(:perform_later)
    end

    it 'enqueues the webhook when an open access work is published' do
      patch dashboard_form_publish_path(work_version), params: request_params

      expect(response).to have_http_status(:redirect)
      expect(WorkPublishedWebhookJob).to have_received(:perform_later).with(work_version.work.uuid)
    end

    context 'when the work is not open access' do
      let(:open_access) { false }

      it 'does not enqueue the webhook' do
        patch dashboard_form_publish_path(work_version), params: request_params

        expect(response).to have_http_status(:redirect)
        expect(WorkPublishedWebhookJob).not_to have_received(:perform_later)
      end
    end
  end

  describe 'GET /dashboard/form/work_versions/:id/open_access_version' do
    let(:work_version) do
      create(:work_version, open_access_version: OpenAccessVersion::VersionValues::ACCEPTED)
    end

    context 'when the user can edit the work version' do
      let(:user) { work_version.work.depositor.user }

      before { sign_in user }

      it 'returns the open access version payload' do
        get "/dashboard/form/work_versions/#{work_version.id}/open_access_version"

        expect(response).to have_http_status(:ok)
        payload = JSON.parse(response.body)
        expect(payload).to eq(
          'id' => work_version.id,
          'open_access_version' => OpenAccessVersion::VersionValues::ACCEPTED
        )
      end
    end

    context 'when the user cannot edit the work version' do
      let(:user) { create(:user) }

      before { sign_in user }

      it 'returns not found' do
        get "/dashboard/form/work_versions/#{work_version.id}/open_access_version"

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
