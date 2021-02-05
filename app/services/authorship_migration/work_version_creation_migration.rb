# frozen_string_literal: true

module AuthorshipMigration
  class WorkVersionCreationMigration
    class << self
      def call(work_version:)
        new(work_version: work_version).call
      end
    end

    attr_reader :work_version

    def initialize(work_version:)
      @work_version = work_version
    end

    def call
      paper_trail_versions__by_creator = all_paper_trail_changes_for_creators.group_by(&:item_id)

      paper_trail_versions__by_creator.each do |_work_version_creation_id, versions|
        migrate_work_version_creation_to_authorship(versions: versions)
      end
    end

    private

      def migrate_work_version_creation_to_authorship(versions:)
        actor_id = extract_author_ids(paper_trail_changes: versions).first

        return if already_migrated?(actor_id: actor_id)

        actor = actor_lookup[actor_id]

        base_authorship_attributes = map_actor_to_authorship_attributes(actor: actor)
          .merge(
            resource_type: 'WorkVersion',
            resource_id: work_version.id
          )

        authorship = nil

        ActiveRecord::Base.transaction do
          versions.each do |version|
            PaperTrail.request(whodunnit: version.whodunnit) do
              case version.event
              when 'create'
                changes = map_paper_trail_updates_to_authorship_attributes(version: version)
                attrs = base_authorship_attributes.merge(changes)
                authorship = Authorship.create!(attrs)
              when 'update'
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
        _actor_ids = paper_trail_changes
          .flat_map { |ptv| ptv.changeset.fetch('actor_id', []) }
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
          alias: actor.default_alias,
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
        version
          .changeset
          .map { |attr, changes| [attr, changes.last] } # changes are in the form [old_val, new_val]
          .to_h
          .with_indifferent_access
          .except(:id, :work_version_id)
      end
  end
end
