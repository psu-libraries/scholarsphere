# frozen_string_literal: true

# @abstract Determines if a given work version is different from its previous version. A work version is different if
# it has different values for any of its metadata attributes, or has different file resources.

class ChangedWorkVersionValidator < ActiveModel::Validator
  attr_reader :work_version

  def validate(record)
    @work_version = record

    if identical?
      record.errors.add(:work_version, 'is the same as the previous version')
    end
  end

  private

    def identical?
      return false if previous_version.nil?

      (work_version.file_resources == previous_version.file_resources) &&
        (metadata_token == metadata_token(previous_version))
    end

    def previous_version
      WorkVersion.find_by(
        work_id: work_version.work_id,
        version_number: work_version.version_number - 1
      )
    end

    def metadata_token(version = nil)
      version ||= work_version

      Digest::MD5.hexdigest(
        version
          .metadata
          .values
          .flatten
          .compact
          .sort
          .join
      )
    end
end
