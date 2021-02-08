# frozen_string_literal: true

module AuthorshipMigration
  class CollectionCreationMigration
    class AuthorMigrationError < StandardError; end

    class << self
      def migrate_all_collections
        errors = []

        Collection.includes(creator_aliases: :actor).find_each do |collection|
          errors << call(collection: collection)
        end

        errors.flatten

        if $stdout.tty?
          errors.each { |err| puts err }
          errors.any? # return true or false
        else
          errors
        end
      end

      def call(collection:)
        errors = []

        collection.creator_aliases.each do |creator_alias|
          next if already_migrated?(collection_id: collection.id, actor_id: creator_alias.actor_id)

          actor = creator_alias.actor

          authorship_attributes = map_actor_to_authorship_attributes(actor: actor)
            .merge(map_creator_alias_to_authorship_attributes(creator_alias: creator_alias))
            .merge(
              resource_type: 'Collection',
              resource_id: collection.id
            )

          Authorship.create!(authorship_attributes)
        rescue ActiveRecord::ActiveRecordError => e
          errors << "Collection##{collection.id}, CollectionCreation##{creator_alias.id}, #{e.message}"
        end

        errors
      end

      private

        def already_migrated?(collection_id:, actor_id:)
          Authorship.where(
            resource_type: 'Collection',
            resource_id: collection_id,
            actor_id: actor_id
          ).any?
        end

        def map_actor_to_authorship_attributes(actor:)
          {
            alias: actor.default_alias,
            given_name: actor.given_name,
            surname: actor.surname,
            email: actor.email
          }.with_indifferent_access
        end

        def map_creator_alias_to_authorship_attributes(creator_alias:)
          creator_alias
            .attributes
            .with_indifferent_access
            .slice(
              :alias,
              :position,
              :actor_id,
              :created_at,
              :updated_at
            )
        end
    end
  end
end
