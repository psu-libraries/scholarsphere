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

        WorkVersion.find_each.with_index do |work_version, index|
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

      paper_trail_versions__by_creator.each do |work_version_creation_id, versions|
        migrate_work_version_creation_to_authorship(versions: versions)
      rescue StandardError => e
        errors << "WorkVersion##{work_version.id}, WorkVersionCreation##{work_version_creation_id}, #{e}"
      end

      errors.empty?
    end

    private

      def migrate_work_version_creation_to_authorship(versions:)
        actor_id = extract_author_ids(paper_trail_changes: versions).first
        actor = actor_lookup[actor_id]

        return if already_migrated?(actor_id: actor_id)

        raise AuthorMigrationError, "Could not find Actor##{actor_id.inspect}" if actor.blank?

        base_authorship_attributes = map_actor_to_authorship_attributes(actor: actor)
          .merge(
            resource_type: 'WorkVersion',
            resource_id: work_version.id
          )

        # Note that we use `new` below with the base attributes coming in from
        # the Actor. The Authorship will be saved to the database after merging
        # in the changeset from the first papertrail version.
        authorship = Authorship.new(base_authorship_attributes)

        ActiveRecord::Base.transaction do
          versions.each do |version|
            PaperTrail.request(whodunnit: version.whodunnit) do
              case version.event
              when 'create', 'update'
                changes = map_paper_trail_updates_to_authorship_attributes(version: version)
                authorship.update!(changes)
              when 'destroy'
                authorship.destroy
              end
            end
          end
        end
      end

      def already_migrated?(actor_id:)
        PaperTrail::Version.where(
          item_type: 'Authorship',
          resource_type: 'WorkVersion',
          resource_id: work_version.id
        ).where_object_changes(actor_id: actor_id).any?
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
      def extract_author_ids(paper_trail_changes:)
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
        actor_ids = extract_author_ids(paper_trail_changes: all_paper_trail_changes_for_creators)

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
          .with_indifferent_access
          .except(:id, :work_version_id)

        # Rename alias to display_name
        attrs[:display_name] = attrs.delete(:alias) if attrs.key?(:alias)

        attrs
      end
  end
end
