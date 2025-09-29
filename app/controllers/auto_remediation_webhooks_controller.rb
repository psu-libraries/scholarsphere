# frozen_string_literal: true

class AutoRemediationWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_request

  def create
    event_type = params[:event_type]
    job_data   = params[:job] || {}

    record = FileResource.find_by(remediation_job_uuid: job_data[:uuid])

    # In the extremely rare case that multiple remediation jobs are kicked off
    # for the same file, the older jobs should fail here since the
    # remediation_job_uuid will no longer be associated with the file.
    unless record
      return render json: { error: 'Record not found' }, status: :not_found
    end

    case event_type
    when 'job.succeeded'
      handle_success(record)
    when 'job.failed'
      handle_failure(job_data)
    else
      Rails.logger.error("Unknown event type received: #{event_type}")
      render json: { error: 'Unknown event type' }, status: :bad_request
    end
  end

  private

    def handle_success(record)
      BuildAutoRemediatedWorkVersion.call(record, replacement_url)
      render json: { message: 'Update successful' }, status: :ok
    rescue StandardError => e
      render json: { error: e.message }, status: :internal_server_error
    end

    def handle_failure(job_data)
      Rails.logger.error("Auto-remediation job failed: #{job_data[:processing_error_message]}")
      render json: { message: job_data[:processing_error_message] }, status: :ok
    end

    def pdf_accessibility_params
      params.permit(
        :event_type,
        job: [:uuid, :status, :output_url, :processing_error_message]
      )
    end

    def authenticate_request
      raise 'PDF_REMEDIATION_WEBHOOK_SECRET not configured.' if ENV['PDF_REMEDIATION_WEBHOOK_SECRET'].blank?

      head(:unauthorized) unless request.headers['X-API-KEY'] == ENV['PDF_REMEDIATION_WEBHOOK_SECRET']
    end
end
