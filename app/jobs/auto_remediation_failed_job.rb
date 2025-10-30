# frozen_string_literal: true

class AutoRemediationFailedJob < ApplicationJob
  queue_as :default

  def perform(job_uuid)
    file_resource = FileResource.find_by(remediation_job_uuid: job_uuid)
    file_resource.update!(auto_remediation_failed_at: Time.current)

    work = file_resource.work_versions&.first&.work

    LibanswersApiService.new
      .admin_create_ticket(work.id,
                           'work_remediation_failed')
  end
end
