namespace :cleanup do
  desc "Destroy orphaned file resources"
  task destroy_orphaned_file_resources: :environment do
    orphaned_file_resources = FileResource.left_joins(:file_version_memberships)
                                          .where(file_version_memberships: { id: nil })

    orphaned_file_resources.each do |file_resource|
      file_resource.destroy
    end
  end
end