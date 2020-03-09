# frozen_string_literal: true

# @abstract Used in conjuction with our REST API, this service publishes a new work with complete metadata and content.
# It is encumbent upon the caller to provied the required metadata and binary content. There are three possible outcomes
# for the work:
# 1. A work has valid metadata and can be published
#      * a new, persisted work is returned in a published state
# 2. A work has valid metadata, but cannot be published due to unmet critera (ex. a private work)
#      * a new, persisted work is returned in a DRAFT state
# 3. A work has invalid metadata or content
#      * a new, UNPERSISTED work is returned with errors

class PublishNewWork
  # @param [Hash] metadata
  # @param [String] depositor
  # @param [Array] content
  # @param [Hash] permissions
  # @return [Work]
  def self.call(metadata:, depositor:, content:, permissions: {})
    user = UserRegistrationService.call(uid: depositor)
    noid = metadata.delete(:noid)

    params = {
      work_type: metadata.delete(:work_type) { Work::Types::DATASET },
      visibility: metadata.delete(:visibility) { Permissions::Visibility::OPEN },
      embargoed_until: metadata.delete(:embargoed_until),
      depositor: user,
      versions_attributes: [metadata.to_hash]
    }

    work = Work.build_with_empty_version(params)
    if noid.present?
      work.legacy_identifiers.find_or_initialize_by(
        version: 3,
        old_id: noid
      )
    end
    UpdatePermissionsService.call(resource: work, permissions: permissions, create_agents: true)
    work_version = work.versions.first

    content.map do |file|
      work_version.file_resources.build(file: file[:file])
    end

    return work unless work.valid?

    work.save unless work_version.publish!
    work.reload
  end
end
