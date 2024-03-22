# frozen_string_literal: true

require 'airrecord'

class CurationTaskClient
  class CurationError < RuntimeError; end

  def self.send_curation(work_version_id, requested: false, updated_version: false)
    submission = WorkVersion.find(work_version_id)
    labels = []
    labels << 'Curation Requested' if requested
    labels << 'Embargoed' if submission.embargoed?
    labels << 'Updated Version' if updated_version

    record =
      {
        ID: submission.uuid,
        'Submission Title': submission.title,
        'Submission Link': submission.submission_link,
        Depositor: submission.depositor_access_id,
        'Depositor Name': submission.depositor_name,
        'Deposit Date': submission.deposited_at,
        Labels: labels
      }

    begin
      Submission.create(record)
      submission.sent_for_curation = Time.zone.now
      submission.save!
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
