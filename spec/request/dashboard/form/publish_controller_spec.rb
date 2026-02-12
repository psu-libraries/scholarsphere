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

      it 'mirrors remediated_version from the work version to associated PDF files' do
        expect(pdf_file.remediated_version).to be false
        expect(non_pdf_file.remediated_version).to be false

        patch dashboard_form_publish_path(work_version), params: request_params

        expect(response).to have_http_status(:redirect)
        expect(pdf_file.reload.remediated_version).to be true
        expect(non_pdf_file.reload.remediated_version).to be false
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
end
