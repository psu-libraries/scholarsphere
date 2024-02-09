# frozen_string_literal: true

require 'airrecord'

class AirtableExporter

  def self.call(work_version_id)
    Airrecord.api_key = ENV['AIRTABLE_API_TOKEN']

    submission = WorkVersion.find(work_version_id)

    record =
      {
        "ID": submission.uuid,
        "Submission Title": submission.title,
        "Submission Link": submission.submission_link,
        "Depositor": submission.depositor_access_id,
        "Depositor Name": submission.depositor_name,
        "Deposit Date": submission.deposited_at,
        "Labels": ["Curation Requested"]
      }

    Submission.create(record)
  end
end