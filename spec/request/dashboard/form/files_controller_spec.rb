# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::Form::FilesController, type: :request do
  describe 'PATCH /dashboard/form/work_versions/:id/files' do
    let(:work_version) { create(:work_version, :draft, open_access: open_access) }
    let(:user) { work_version.depositor.user }
    let(:open_access) { true }
    let(:request_params) { { work_version: { ignored: '1' } } }

    before do
      allow(OpenAccessVersionGuesserJob).to receive(:perform_later)
      sign_in user
    end

    context 'when open access is enabled' do
      let(:open_access) { true }

      it 'enqueues open access version guessing' do
        patch dashboard_form_files_path(work_version), params: request_params

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(dashboard_form_publish_path(work_version))
        expect(OpenAccessVersionGuesserJob).to have_received(:perform_later).with(work_version.id)
      end
    end

    context 'when open access is disabled' do
      let(:open_access) { false }

      it 'does not enqueue open access version guessing' do
        patch dashboard_form_files_path(work_version), params: request_params

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(dashboard_form_publish_path(work_version))
        expect(OpenAccessVersionGuesserJob).not_to have_received(:perform_later)
      end
    end
  end
end
