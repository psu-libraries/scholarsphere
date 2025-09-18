# frozen_string_literal: true

class AutoRemediationJob < ApplicationJob
  queue_as :auto_remediation

  def perform(file_resource_id)
    file_resource = FileResource.find(file_resource_id)

    begin
      remediation_job_uuid = PdfRemediation::Client.new(file_resource.file_url).request_remediation
      file_resource.update(remediation_job_uuid: remediation_job_uuid)
    rescue StandardError => e
      Rails.logger.error("Failed to auto remediate #{file_resource.id}: #{e.message}")
      raise e
    end
  end
end
