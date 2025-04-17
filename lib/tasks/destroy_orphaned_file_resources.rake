# frozen_string_literal: true

namespace :cleanup do
  desc 'Destroy orphaned file resources'
  task destroy_orphaned_file_resources: :environment do
    orphaned_file_resources = FileResource.where.missing(:file_version_memberships)

    orphaned_file_resources.each(&:destroy)
  end
end
