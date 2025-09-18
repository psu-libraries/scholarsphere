# frozen_string_literal: true

class AutoRemediateService
  attr_reader :work_version, :admin, :download_is_pdf

  def initialize(work_version_id, is_admin, download_is_pdf)
    @work_version = WorkVersion.find(work_version_id)
    @admin = is_admin
    @download_is_pdf = download_is_pdf
  end

  def call
    work_version.update(remediation_started_at: Time.current)
    pdfs = work_version.file_resources.where("file_resources.file_data->'metadata'->>'mime_type' = ?", 'application/pdf')
    pdfs.each do |pdf|
      AutoRemediationJob.perform_later(pdf.id) if pdf.remediation_job_uuid.blank?
    end
  end

  def able_to_auto_remediate?
    work_version.latest_published_version? &&
      work_version.remediation_started_at.nil? &&
      !work_version.auto_remediated_version &&
      download_is_pdf &&
      !admin
  end
end
