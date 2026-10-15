# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::Form::FilesController, type: :request do
  describe 'GET /dashboard/form/work_versions/:id/files' do
    let(:work_version) { create(:work_version, :draft) }

    it 'redirects unauthenticated files edit requests to azure auth handoff' do
      path = dashboard_form_files_path(work_version)

      get path

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(user_azure_oauth_redirect_path(return_to: path))
    end
  end

  describe 'PATCH /dashboard/form/work_versions/:id/files' do
    let(:work_version) do
      create(
        :work_version,
        :draft,
        work: build(:work, work_type: work_type),
        open_access_upload: open_access,
        open_access_version: OpenAccessVersion::VersionValues::ACCEPTED
      )
    end
    let(:user) { work_version.depositor.user }
    let(:open_access) { true }
    let(:work_type) { 'article' }
    let(:request_params) { { work_version: { id: work_version.id } } }

    before do
      allow(OpenAccessVersionGuesserJob).to receive(:perform_later)
      sign_in user
    end

    context 'when open access is enabled' do
      let(:open_access) { true }

      it 'enqueues open access version guessing and resets open_access_version' do
        patch dashboard_form_files_path(work_version), params: request_params

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(dashboard_form_publish_path(work_version))
        expect(OpenAccessVersionGuesserJob).to have_received(:perform_later).with(work_version.id)
        expect(work_version.reload.open_access_version).to be_nil
      end

      context 'when the work type is not OA-eligible' do
        let(:work_type) { 'research_paper' }

        it 'does not enqueue open access version guessing' do
          patch dashboard_form_files_path(work_version), params: request_params

          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(dashboard_form_publish_path(work_version))
          expect(OpenAccessVersionGuesserJob).not_to have_received(:perform_later)
        end
      end
    end

    context 'when open access is disabled' do
      let(:open_access) { false }

      it 'does not enqueue open access version guessing' do
        patch dashboard_form_files_path(work_version), params: request_params

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(dashboard_form_publish_path(work_version))
        expect(OpenAccessVersionGuesserJob).not_to have_received(:perform_later)
        expect(work_version.reload.open_access_version).to eq(OpenAccessVersion::VersionValues::ACCEPTED)
      end
    end
  end
end
