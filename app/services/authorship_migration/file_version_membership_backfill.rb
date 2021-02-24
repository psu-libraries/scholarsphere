# frozen_string_literal: true

module AuthorshipMigration
  class FileVersionMembershipBackfill
    attr_reader :previous_version,
                :next_version

    def self.backfill_all_file_version_memberships
      works_with_multiple_versions = Work
        .includes(versions: [:file_version_memberships])
        .joins(:versions)
        .where('work_versions.version_number > 1')
        .distinct

      works_with_multiple_versions.find_each do |work|
        work.versions.sort_by(&:version_number).each_cons(2) do |previous_version, next_version|
          new(previous_version: previous_version, next_version: next_version)
            .call
        end
      end
    end

    def initialize(previous_version:, next_version:)
      raise ArgumentError if previous_version.version_number >= next_version.version_number

      @previous_version = previous_version
      @next_version = next_version
    end

    def call
      old_file_memberships_by_file_id = previous_version
        .file_version_memberships
        .index_by(&:file_resource_id)

      next_version.file_version_memberships.each do |new_fvm|
        corresponding_old_fvm = old_file_memberships_by_file_id[new_fvm.file_resource_id]

        next if corresponding_old_fvm.nil?
        next if new_fvm.versions.first&.event == 'create'

        object_changes = {
          'id' => [nil, new_fvm.id],
          'title' => [nil, corresponding_old_fvm.title],
          'created_at' => [nil, next_version.created_at],
          'updated_at' => [nil, next_version.created_at],
          'work_version_id' => [nil, new_fvm.work_version_id],
          'file_resource_id' => [nil, new_fvm.file_resource_id]
        }

        PaperTrail::Version.create(
          changed_by_system: true,
          item_type: new_fvm.class.name,
          item_id: new_fvm.id,
          event: 'create',
          whodunnit: corresponding_old_fvm.versions.last.whodunnit,
          created_at: previous_version.created_at,
          work_version_id: next_version.id,
          resource_id: next_version.id,
          resource_type: next_version.class.name,
          object_changes: object_changes
        )
      end
    end
  end
end
