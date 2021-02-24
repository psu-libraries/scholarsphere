# frozen_string_literal: true

module AuthorshipMigration
  class FileVersionMembershipMigration
    def self.migrate_all_file_version_memberships
      ::AuthorshipMigration::FileVersionMembershipBackfill.backfill_all_file_version_memberships

      PaperTrail::Version
        .where(item_type: 'FileVersionMembership')
        .find_each do |pt_version|
          pt_version.update(
            resource_type: 'WorkVersion',
            resource_id: pt_version.work_version_id
          )
        end
    end
  end
end
