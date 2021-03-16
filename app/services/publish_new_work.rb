# frozen_string_literal: true

# @abstract Used in conjunction with our REST API, this service publishes a new work with complete metadata and content.
# It is incumbent upon the caller to provide the required metadata and binary content. If all the information is
# provided and is correct, the work will be published; otherwise, errors are returned:
# * A work has valid metadata and can be published
#      * a new, persisted work is returned in a published state
# * A work has invalid metadata or content
#      * a new, UNPERSISTED work is returned with errors

class PublishNewWork
  # @param [ActionController::Parameters] metadata
  # @param [ActionController::Parameters] depositor
  # @param [Array<ActionController::Parameters>] content
  # @param [ActionController::Parameters] permissions
  # @return [Work]
  def self.call(metadata:, depositor:, content:, permissions: {})
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
      work_type: metadata.delete(:work_type),
      visibility: metadata.delete(:visibility),
      embargoed_until: metadata.delete(:embargoed_until),
      depositor: depositor_actor,
      deposited_at: metadata.delete(:deposited_at),
      doi: metadata.delete(:doi),
      versions_attributes: [metadata.to_hash.merge!('creators_attributes' => creators_attributes)]
    }

    work = Work.build_with_empty_version(params)

    WorkVersion.transaction do
      UpdatePermissionsService.call(resource: work, permissions: permissions, create_agents: true)
      work_version = work.versions.first

      content.map do |file|
        work_version.file_resources.build(file: file[:file], deposited_at: file[:deposited_at])
      end

      work_version.publish
      work_version.save!
      work.reload
    end
  rescue ActiveRecord::RecordInvalid
    work
  end
end
