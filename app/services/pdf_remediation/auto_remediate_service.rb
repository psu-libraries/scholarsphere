# frozen_string_literal: true

class PdfRemediation::AutoRemediateService
  attr_reader :work_version, :admin, :download_can_remediate

  def initialize(work_version_id, is_admin, download_can_remediate)
    @work_version = WorkVersion.find(work_version_id)
    @admin = is_admin
    @download_can_remediate = download_can_remediate
  end

  def call
    work_version.update(auto_remediation_started_at: Time.current)
    pdfs = work_version.file_resources.can_remediate
    pdfs.each do |pdf|
      PdfRemediation::AutoRemediationJob.perform_later(pdf.id) if pdf.remediation_job_uuid.blank?
    end
  end

  def able_to_auto_remediate?
    # Feature flag: enable accessibility auto-remediation in production
    # TODO: Remove following line when we are confident in the stability of the remediation service
    return false if Rails.env.production? && ENV['ENABLE_ACCESSIBILITY_REMEDIATION'] != 'true'

    work_version.latest_published_version? &&
      work_version.auto_remediation_started_at.nil? &&
      !work_version.auto_remediated_version &&
      download_can_remediate &&
      !admin &&
      !work_version.work.under_manual_review
  end
end
