# frozen_string_literal: true

class PdfRemediation::AutoRemediationFailedJob < ApplicationJob
  queue_as :default

  def perform(job_uuid)
    work = FileResource.find_by!(remediation_job_uuid: job_uuid)
      .work_versions
      &.first
      &.work

    LibanswersApiService.new
      .admin_create_ticket(work.id,
                           'work_remediation_failed')
  end
end
