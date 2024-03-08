# frozen_string_literal: true

require 'airrecord'

class CurationTaskClient
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

  def self.find(uuid)
    Airrecord.api_key = ENV['AIRTABLE_API_TOKEN']

    begin
      Submission.all(filter: "{ID} = '#{uuid}'")
    rescue Airrecord::Error => e
      raise CurationError.new(e)
    end
  end

  def self.find_all(work_id)
    Airrecord.api_key = ENV['AIRTABLE_API_TOKEN']

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

  def self.remove(airtable_id)
    Airrecord.api_key = ENV['AIRTABLE_API_TOKEN']

    begin
      record = Submission.find(airtable_id)
      record.destroy
    rescue Airrecord::Error => e
      raise CurationError.new(e)
    end
  end
end
