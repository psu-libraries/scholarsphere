# frozen_string_literal: true

class BuildAutoRemediatedWorkVersionJob < ApplicationJob
  queue_as :auto_remediation

  def perform(remediation_job_uuid, remediated_file_url)
    # In the extremely rare case that multiple remediation jobs are kicked off
    # for the same file, the older jobs should fail here since the
    # remediation_job_uuid will no longer be associated with the file.
    file_resource = FileResource.find_by!(remediation_job_uuid: remediation_job_uuid)

    BuildAutoRemediatedWorkVersion.call(file_resource, remediated_file_url)
  end
end
