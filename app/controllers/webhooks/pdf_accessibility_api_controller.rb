# frozen_string_literal: true

class Webhooks::PdfAccessibilityApiController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_request

  def create
    event_type = params[:event_type]
    job_data   = params[:job] || {}

    case event_type
    when 'job.succeeded'
      handle_success(job_data)
    when 'job.failed'
      handle_failure(job_data)
    else
      Rails.logger.error("Unknown event type received: #{event_type}")
      render json: { error: 'Unknown event type' }, status: :bad_request
    end
  end

  private

    def handle_success(job_data)
      BuildAutoRemediatedWorkVersionJob.perform_later(job_data[:uuid], job_data[:output_url])
      render json: { message: 'Update successful' }, status: :ok
    rescue StandardError => e
      store_failure(job_data[:uuid])
      render json: { error: e.message }, status: :internal_server_error
    end

    def handle_failure(job_data)
      Rails.logger.error("Auto-remediation job failed: #{job_data[:processing_error_message]}")
      AutoRemediationFailedJob.perform_later(job_data[:uuid])
      store_failure(job_data[:uuid])
      render json: { message: job_data[:processing_error_message] }, status: :ok
    end

    def pdf_accessibility_params
      params.permit(
        :event_type,
        job: [:uuid, :status, :output_url, :processing_error_message]
      )
    end

    def authenticate_request
      token = ExternalApp.pdf_accessibility_api.token.to_s
      provided = request.headers['X-API-KEY'].to_s

      return head(:unauthorized) if provided.blank?

      head(:unauthorized) unless ActiveSupport::SecurityUtils.secure_compare(provided, token)
    end

    def store_failure(job_uuid)
      file_resource = FileResource.find_by(remediation_job_uuid: job_uuid)
      file_resource.update(auto_remediation_failed_at: Time.current)
    end
end
