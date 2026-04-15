# frozen_string_literal: true

namespace :pdf_remediation do
  desc 'Flag existing remediated WorkVersions that have AccessibleCopy_ filename prefix'
  task flag_existing_remediated_files_and_work_versions: :environment do
    scope = FileResource.where("file_data->'metadata'->>'filename' LIKE ?", 'AccessibleCopy_%')

    puts "Found #{scope.count} FileResource records with AccessibleCopy_ filename prefix"

    scope.find_each do |file_resource|
      file_resource.update_columns(remediated_version: true) # rubocop:disable Rails/SkipsModelValidations

      latest_work_version = file_resource.work_versions.order(:version_number).last ||
        file_resource.work_versions.order(:created_at).last

      latest_work_version.update_columns(remediated_version: true) # rubocop:disable Rails/SkipsModelValidations

      puts "Flagged WorkVersion ##{latest_work_version.id} and FileResource ##{file_resource.id} as remediated_version"
    end
  end

  desc 'Reset failed auto-remediation fields for FileResources within a date range (start_date, end_date)'
  task :reset_failed_auto_remediation, %i[start_date end_date] => :environment do |_task, args|
    start_date = args[:start_date]
    end_date = args[:end_date]

    if start_date.blank? || end_date.blank?
      raise ArgumentError, 'Usage: rake pdf_remediation:reset_failed_auto_remediation[start_date,end_date]'
    end

    begin
      start_time = parse_date_range_arg(start_date, end_of_day: false)
      end_time = parse_date_range_arg(end_date, end_of_day: true)
    rescue Date::Error
      raise ArgumentError, 'Invalid date arguments. Expected YYYY-MM-DD or parseable datetime strings.'
    end

    scope = FileResource.where(auto_remediation_failed_at: start_time..end_time)

    puts "Found #{scope.count} FileResource records between #{start_time} and #{end_time}"

    scope.find_each do |file_resource|
      file_resource.update_columns( # rubocop:disable Rails/SkipsModelValidations
        auto_remediation_failed_at: nil,
        remediation_job_uuid: nil
      )

      latest_work_version = file_resource.latest_remediation_work_version_candidate
      latest_work_version&.update_columns(auto_remediation_started_at: nil) # rubocop:disable Rails/SkipsModelValidations

      puts "Reset FileResource ##{file_resource.id} " \
           "and WorkVersion ##{latest_work_version&.id || 'none'}"
    end
  end
end

def parse_date_range_arg(value, end_of_day:)
  if value.match?(/\A\d{4}-\d{2}-\d{2}\z/)
    date = Date.iso8601(value)
    return end_of_day ? date.end_of_day : date.beginning_of_day
  end

  Time.zone.parse(value)
end
