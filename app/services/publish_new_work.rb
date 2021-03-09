# frozen_string_literal: true

# @abstract Used in conjunction with our REST API, this service publishes a new work with complete metadata and content.
# It is incumbent upon the caller to provide the required metadata and binary content. Here are the possible outcomes:
# for the work:
# 1. A work has valid metadata and can be published
#      * a new, persisted work is returned in a published state
# 2. A work has valid metadata, but cannot be published due to unmet critera (ex. a private work)
#      * a new, persisted work is returned in a DRAFT state
# 3. A work has invalid metadata or content
#      * a new, UNPERSISTED work is returned with errors

class PublishNewWork
  # @param [ActionController::Parameters] metadata
  # @param [ActionController::Parameters] depositor
  # @param [Array<ActionController::Parameters>] content
  # @param [ActionController::Parameters] permissions
  # @return [Work]
  def self.call(metadata:, depositor:, content:, permissions: {})
    noid = metadata.delete(:noid)
    deposited_at = metadata.delete(:deposited_at)
    metadata[:rights] ||= WorkVersion::Licenses::DEFAULT

    # @todo start a transaction here in case we need to rollback and remove any Actors we've created

    depositor_actor = Actor.find_or_create_by(psu_id: depositor['psu_id']) do |actor|
      actor.attributes = depositor
    end

    creators_attributes = metadata.to_hash.fetch('creators_attributes', []).map do |attributes|
      actor_attributes = attributes['actor_attributes']
      psu_id = actor_attributes['psu_id']

      actor = if psu_id.present?
                Actor.find_or_create_by(psu_id: psu_id) do |new_actor|
                  new_actor.attributes = actor_attributes
                end
              else
                Actor.find_or_create_by(actor_attributes)
              end

      { display_name: attributes['display_name'], given_name: actor.given_name, surname: actor.surname, actor: actor }
    end

    params = {
      work_type: (metadata.delete(:work_type).presence || Work::Types.unspecified),
      visibility: metadata.delete(:visibility) { Permissions::Visibility::OPEN },
      embargoed_until: metadata.delete(:embargoed_until),
      depositor: depositor_actor,
      deposited_at: deposited_at,
      doi: metadata.delete(:doi),
      versions_attributes: [metadata.to_hash.merge!('creators_attributes' => creators_attributes)]
    }

    work = Work.build_with_empty_version(params)
    LegacyIdentifier.create_noid(resource: work, noid: noid)
    UpdatePermissionsService.call(resource: work, permissions: permissions, create_agents: true)
    work_version = work.versions.first

    content.map do |file|
      file_resource = work_version.file_resources.build(file: file[:file], deposited_at: file[:deposited_at])
      LegacyIdentifier.create_noid(resource: file_resource, noid: file[:noid])
    end

    return work unless work.valid?

    # Publish the work version (without saving), check if it's valid. If it's
    # not valid, roll back to previous state
    begin
      work_version.publish
      work_version.validate!
    rescue ActiveRecord::RecordInvalid
      work_version.aasm_state = work_version.aasm.from_state
    end

    if work.save
      work.reload
    else
      work
    end
  end
end
