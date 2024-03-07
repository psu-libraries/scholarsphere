# frozen_string_literal: true

require 'airrecord'

class CurationTaskExporter
  class CurationError < RuntimeError; end

  def self.send_curation(work_version_id, requested: false)
    Airrecord.api_key = ENV['AIRTABLE_API_TOKEN']

    submission = WorkVersion.find(work_version_id)
    labels = requested ? ['Curation Requested'] : []

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
    rescue Airrecord::Error => e
      raise CurationError.new(e)
    end
  end
end
