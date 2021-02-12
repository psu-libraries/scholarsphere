# frozen_string_literal: true

module AuthorshipMigration
  class WorkVersionCreationMigration
    class AuthorMigrationError < StandardError; end

    class << self
      def call(work_version:)
        instance = new(work_version: work_version)
        instance.call
        instance.errors
      end

      def migrate_all_work_versions
        errors = []

        WorkVersion.includes(creator_aliases: :actor).find_each.with_index do |work_version, index|
          print '.' if $stdout.tty? && (index % 100).zero?
          errors << call(work_version: work_version)
        end

        errors = errors.flatten

        if $stdout.tty?
          puts 'done'
          errors.each { |err| puts err }
          errors.empty? # return true or false
        else
          errors
        end
      end
    end

    attr_reader :work_version,
                :errors

    def initialize(work_version:)
      @work_version = work_version
      @errors = []
    end

    def call
      @errors = []

      paper_trail_versions__by_creator = all_paper_trail_changes_for_creators.group_by(&:item_id)

      # Use papertrail as much as possible, so that we can maintain the editing
      # (and deletion!) history of an Author.
      paper_trail_versions__by_creator.each do |work_version_creation_id, versions|
        migrate_paper_trail_versions_to_authorship(
          work_version_creation_id: work_version_creation_id,
          versions: versions
        )
      rescue StandardError => e
        errors << "WorkVersion##{work_version.id}, WorkVersionCreation##{work_version_creation_id}, #{e}"
      end

      # The way the papertrail history works, on a second (or subsequent)
      # version, there are no `create` events created in papertrail. This is
      # because those authors aren't really "created", as in we're not adding
      # more authors, we're just maintaining the same ones but copying them
      # across to the new work version. As a result, these authors on second
      # versions need to be copied across without using papertrail.
      if work_version.version_number > 1
        actors_present_in_papertrail = Set.new(
          extract_actor_ids(paper_trail_changes: all_paper_trail_changes_for_creators)
        )

        creator_aliases_not_in_papertrail = work_version
          .creator_aliases
          .reject { |work_version_creation| actors_present_in_papertrail.include? work_version_creation.actor_id }

        creator_aliases_not_in_papertrail.each do |creator_alias|
          silently_migrate_creator_alias_to_authorship(creator_alias: creator_alias)
        rescue ActiveRecord::ActiveRecordError => e
          errors << "WorkVersion##{work_version.id}, WorkVersionCreation##{creator_alias.id}, #{e.message}"
        end
      end

      errors.empty?
    end

    private

      def migrate_paper_trail_versions_to_authorship(versions:, work_version_creation_id:)
        actor_id = extract_actor_ids(paper_trail_changes: versions).first
        actor = actor_lookup[actor_id]

        return if already_migrated?(actor_id: actor_id)

        if versions.first.event != 'create' && work_version.version_number == 1
          raise(AuthorMigrationError,
                'Cannot find the PaperTrail::Version for when the record was created')
        end
        raise AuthorMigrationError, "Could not find Actor##{actor_id.inspect}" if actor.blank?

        base_authorship_attributes = map_actor_to_authorship_attributes(actor: actor)
          .merge(
            resource_type: 'WorkVersion',
            resource_id: work_version.id
          )

        authorship = if work_version.version_number > 1 && versions.first.event != 'create'
                       silently_migrate_creator_alias_to_authorship(creator_alias: versions.first.reify)
                     else
                       # Note that we use `new` below with the base attributes coming in from
                       # the Actor. The Authorship will be saved to the database after merging
                       # in the changeset from the first papertrail version.
                       Authorship.new(base_authorship_attributes)
                     end

        ActiveRecord::Base.transaction do
          versions.each_with_index do |version, index|
            is_last_version = index == versions.length - 1

            PaperTrail.request(whodunnit: version.whodunnit) do
              case version.event
              when 'create', 'update'
                changes = map_paper_trail_updates_to_authorship_attributes(version: version)

                # We did a bug fix on our work_version_creations table that
                # inserted missing positions into the database. However, when we
                # did this bug fix we chose not to write a papertrail::version,
                # so this code here has no knowledge of this fix being done. As
                # a result we need to pull the final position from the current
                # state of the database (if available) and write it to the
                # Authorship if it's different than what currently exists
                if is_last_version &&
                    creator_alias = work_version.creator_aliases
                        .find { |wvc| wvc.id == work_version_creation_id }.presence
                  changes[:position] = creator_alias.position
                end

                authorship.update!(changes)
              when 'destroy'
                authorship.destroy
              end
            end
          end
        end
      end

      def silently_migrate_creator_alias_to_authorship(creator_alias:)
        return if already_migrated?(actor_id: creator_alias.actor_id)

        # Minor db optimization here
        actor = actor_lookup.fetch(creator_alias.actor_id, creator_alias.actor)

        authorship_attributes = map_actor_to_authorship_attributes(actor: actor)
          .merge(map_creator_alias_to_authorship_attributes(creator_alias: creator_alias))
          .merge(
            resource_type: 'WorkVersion',
            resource_id: work_version.id,
            changed_by_system: true # Do not write a PaperTrail::Version
          )

        Authorship.create!(authorship_attributes)
          .tap { |a| a.changed_by_system = false }
      end

      def already_migrated?(actor_id:)
        PaperTrail::Version
          .where_object_changes(actor_id: actor_id)
          .or(PaperTrail::Version.where_object(actor_id: actor_id))
          .where(
            item_type: 'Authorship',
            resource_type: 'WorkVersion',
            resource_id: work_version.id
          )
          .any? ||
          Authorship.where(
            resource_type: 'WorkVersion',
            resource_id: work_version.id,
            actor_id: actor_id
          ).any?
      end

      def all_paper_trail_changes_for_creators
        @all_paper_trail_changes_for_creators ||= PaperTrail::Version
          .where(
            item_type: 'WorkVersionCreation',
            work_version_id: work_version.id
          )
          .order(created_at: :asc)
      end

      # Takes a list of paper trail changes, and extracts all unique actor ids
      def extract_actor_ids(paper_trail_changes:)
        actor_change_sets = paper_trail_changes
          .flat_map { |ptv| ptv.changeset.fetch('actor_id', []) }

        actor_objects = paper_trail_changes
          .flat_map { |ptv| (ptv.object || {}).fetch('actor_id', []) }

        (actor_change_sets + actor_objects)
          .compact
          .uniq
      end

      # Returns a hash in the form of
      #   {id => Actor record}
      def actor_lookup
        @actor_lookup ||= load_actor_lookup
      end

      def load_actor_lookup
        actor_ids = extract_actor_ids(paper_trail_changes: all_paper_trail_changes_for_creators)

        Actor
          .where(id: actor_ids)
          .index_by(&:id)
      end

      def map_actor_to_authorship_attributes(actor:)
        {
          display_name: actor.default_alias,
          given_name: actor.given_name,
          surname: actor.surname,
          email: actor.email
        }.with_indifferent_access
      end

      def map_creator_alias_to_authorship_attributes(creator_alias:)
        attrs = creator_alias.attributes
        map_creator_alias_attributes_to_authorship_attributes(attributes: attrs)
      end

      # Accepts a PaperTrail::Version representing a change to a
      # WorkVersionCreation
      #
      # Returns a hash of these changes, with the appropriate attribute names
      # for an Authorship
      def map_paper_trail_updates_to_authorship_attributes(version:)
        attrs = version
          .changeset
          .map { |attr, changes| [attr, changes.last] } # changes are in the form [old_val, new_val]
          .to_h

        map_creator_alias_attributes_to_authorship_attributes(attributes: attrs)
      end

      def map_creator_alias_attributes_to_authorship_attributes(attributes:)
        attrs = attributes
          .with_indifferent_access
          .slice(
            :alias,
            :position,
            :actor_id,
            :created_at,
            :updated_at
          )

        # Rename alias to display_name
        attrs[:display_name] = attrs.delete(:alias) if attrs.key?(:alias)

        attrs
      end
  end
end
