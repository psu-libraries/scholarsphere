# frozen_string_literal: true

# @abstract Used in conjunction with our REST API, this service creates a new collection.
# It is incumbent upon the caller to provide the required metadata. Here are the possible outcomes:
# 1. A collection has valid metadata and all its member works exist (regardless of their state)
#      * a new, persisted collection is returned
# 2. A collection has valid metadata, but some of its member works do not exist
#      * a new, UNPERSISTED collection is returned with errors
# 3. A collection has invalid metadata
#      * a new, UNPERSISTED collection is returned with errors

class CreateNewCollection
  # @param [ActionController::Parameters] metadata
  # @param [ActionController::Parameters] depositor
  # @param [ActionController::Parameters] permissions
  # @return [Collection]
  def self.call(metadata:, depositor:, permissions: {})
    noid = metadata.delete(:noid)

    # @todo start a transaction here in case we need to rollback and remove any Actors we've created

    depositor_actor = Actor.find_or_create_by(psu_id: depositor['psu_id']) do |actor|
      actor.attributes = depositor
    end

    creator_aliases_attributes = metadata.to_hash.fetch('creator_aliases_attributes', []).map do |attributes|
      actor_attributes = attributes['actor_attributes']
      psu_id = actor_attributes['psu_id']

      actor = if psu_id.present?
                Actor.find_or_create_by(psu_id: psu_id) do |new_actor|
                  new_actor.attributes = actor_attributes
                end
              else
                Actor.find_or_create_by(actor_attributes)
              end

      { alias: attributes['alias'], actor: actor }
    end

    params = metadata.to_hash.merge!(
      'creator_aliases_attributes' => creator_aliases_attributes,
      'visibility' => Permissions::Visibility::OPEN,
      'depositor' => depositor_actor
    )

    collection = Collection.new(params)
    if noid.present?
      collection.legacy_identifiers.find_or_initialize_by(
        version: 3,
        old_id: noid
      )
    end
    UpdatePermissionsService.call(resource: collection, permissions: permissions, create_agents: true)

    if collection.save(context: :migration_api)
      collection.reload
    else
      collection
    end
  end
end
