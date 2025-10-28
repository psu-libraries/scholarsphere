# frozen_string_literal: true

require 'airrecord'

class CurationTaskClient
  class CurationError < RuntimeError; end

  def self.send_curation(work_version_id, requested: false, remediation_requested: false, updated_version: false)
    work_version = WorkVersion.find(work_version_id)
    labels = []
    labels << 'Curation Requested' if requested
    labels << 'Embargoed' if work_version.embargoed?
    labels << 'Updated Version' if updated_version
    labels << 'Accessibility Remediation Requested' if remediation_requested
    labels << 'Needs Accessibility Review' if work_version.needs_accessibility_review
    labels << 'Large PDF' if work_version.has_large_pdf_file_resource?

    record =
      {
        ID: work_version.uuid,
        'Submission Title': work_version.title,
        'Submission Link': work_version.submission_link,
        Depositor: work_version.depositor_access_id,
        'Depositor Name': work_version.depositor_name,
        'Deposit Date': work_version.deposited_at,
        Labels: labels
      }

    begin
      Submission.create(record)
      work_version.sent_for_curation_at = Time.zone.now
      work_version.save!
    rescue Airrecord::Error => e
      raise CurationError.new(e)
    end
  end

  def self.find_all(work_id)
    uuids = Work.find(work_id).versions.pluck('uuid')
    submissions = []

    begin
      uuids.each do |uuid|
        submissions.concat(Submission.all(filter: "{ID} = '#{uuid}'"))
      end
      submissions
    rescue Airrecord::Error => e
      raise CurationError.new(e)
    end
  end
end
