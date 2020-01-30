# frozen_string_literal: true

# @abstract Used in conjuction with our REST API, this service publishes a new work with complete metadata and content.
# It is encumbent upon the caller to provied the required metadata and binary content.

class PublishNewWork
  # @param [Hash] metadata
  # @param [String] depositor
  # @param [Array] content
  # @param [Hash] permissions
  def self.call(metadata:, depositor:, content:, permissions: {})
    user = UserRegistrationService.call(uid: depositor)

    params = {
      work_type: metadata.delete(:work_type) { Work::Types::DATASET },
      visibility: metadata.delete(:visibility) { Permissions::Visibility::OPEN },
      depositor: user,
      versions_attributes: [metadata.to_hash]
    }

    work = Work.build_with_empty_version(params)
    UpdatePermissionsService.call(resource: work, permissions: permissions, create_agents: true)
    work_version = work.versions.first

    content.map do |file|
      work_version.file_resources.build(file: file[:file])
    end

    work_version.publish

    if work.save
      work.reload
    else
      work
    end
  end
end
