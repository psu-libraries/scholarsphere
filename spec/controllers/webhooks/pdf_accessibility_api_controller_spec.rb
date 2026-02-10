# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Webhooks::PdfAccessibilityApiController do
  let(:secret) { 'test-secret' }
  let(:output_url) { nil }
  let(:error_message) { nil }
  let(:params) do
    { event_type: event_type,
      job: { uuid: job_uuid,
             output_url: output_url,
             processing_error_message: error_message } }
  end

  before do
    allow(PdfRemediation::BuildAutoRemediatedWorkVersionJob).to receive(:perform_later).and_return(nil)
    allow(PdfRemediation::AutoRemediationFailedJob).to receive(:perform_later).and_return(nil)
  end

  describe 'POST #create' do
    context 'when X-API-KEY header is missing or incorrect' do
      let(:event_type) { 'job.succeeded' }
      let(:job_uuid) { 'x' }

      it 'returns 401 Unauthorized' do
        post :create, params: params
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authentication succeeds' do
      before do
        request.headers['X-API-KEY'] = ExternalApp.pdf_accessibility_api.webhook_token
      end

      describe 'when event_type is unknown' do
        let(:file) { create(:file_resource, remediation_job_uuid: 'uuid-1') }
        let(:event_type) { 'something_else' }
        let(:job_uuid) { file.remediation_job_uuid }

        before do
          allow(Rails.logger).to receive(:error)
        end

        it 'logs an error and returns 400' do
          post :create, params: params, as: :json
          expect(response).to have_http_status(:bad_request)
          expect(response.parsed_body).to include('error' => 'Unknown event type')
          expect(Rails.logger).to have_received(:error).with(/Unknown event type received/)
        end
      end

      describe 'job.succeeded handling' do
        let(:file) { create(:file_resource, remediation_job_uuid: 'uuid-2') }
        let(:event_type) { 'job.succeeded' }
        let(:job_uuid) { file.remediation_job_uuid }
        let(:output_url) { 'https://example.com/out.pdf' }

        it 'enqueues PdfRemediation::BuildAutoRemediatedWorkVersionJob with record id and output_url and returns 200' do
          post :create, params: params, as: :json

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to include('message' => 'Update successful')
          expect(PdfRemediation::BuildAutoRemediatedWorkVersionJob).to have_received(:perform_later)
            .with(file.remediation_job_uuid, 'https://example.com/out.pdf')
        end

        context 'when an error occurs enqueuing the job' do
          before do
            allow(PdfRemediation::BuildAutoRemediatedWorkVersionJob)
              .to receive(:perform_later).and_raise(StandardError.new('Redis error'))
            allow(Rails.logger).to receive(:error)
          end

          it 'stores the failure timestamp and returns 500 with the error message' do
            post :create, params: params, as: :json

            expect(response).to have_http_status(:internal_server_error)
            expect(response.parsed_body).to include('error' => 'Redis error')
            expect(file.reload.auto_remediation_failed_at).not_to be_nil
          end
        end
      end

      describe 'job.failed handling' do
        let(:file) { create(:file_resource, remediation_job_uuid: 'uuid-3') }
        let(:event_type) { 'job.failed' }
        let(:job_uuid) { file.remediation_job_uuid }
        let(:error_message) { 'Something went wrong' }

        before do
          allow(Rails.logger).to receive(:error)
        end

        it 'logs the failure, enqueues the failed job, stores the failure timestamp and returns 200 with the processing message' do
          post :create, params: params, as: :json

          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to include('message' => error_message)
          expect(Rails.logger).to have_received(:error)
            .with("Auto-remediation job failed: #{error_message}")
          expect(PdfRemediation::AutoRemediationFailedJob)
            .to have_received(:perform_later).with(file.remediation_job_uuid)
          expect(file.reload.auto_remediation_failed_at).not_to be_nil
        end
      end
    end
  end
end
