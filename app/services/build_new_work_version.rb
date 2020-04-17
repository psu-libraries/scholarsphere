# frozen_string_literal: true

class BuildNewWorkVersion
  def self.call(previous_version)
    parent_work = previous_version.work
    highest_version_number = parent_work.versions.maximum(:version_number).to_i

    # Instantiate new draft version using the previous version's metadata and increment the version number
    new_version = parent_work.versions.build(
      metadata: previous_version.metadata,
      aasm_state: WorkVersion::STATE_DRAFT,
      version_number: highest_version_number + 1
    )

    # Copy over files
    previous_version.file_version_memberships.each do |previous_membership|
      new_version.file_version_memberships.build(
        file_resource_id: previous_membership.file_resource_id,
        title: previous_membership.title,
        changed_by_system: true # mute papertrail for this change
      )
    end

    # Copy over creators
    previous_version.creator_aliases.each do |previous_creation|
      new_version.creator_aliases.build(
        actor_id: previous_creation.actor_id,
        alias: previous_creation.alias,
        changed_by_system: true # mute papertrail for this change
      )
    end

    new_version
  end
end
