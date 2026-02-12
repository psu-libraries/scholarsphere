# frozen_string_literal: true

namespace :pdf_remediation do
  desc 'Flag existing remediated WorkVersions that have AccessibleCopy_ filename prefix'
  task flag_existing_remediated_files_and_work_versions: :environment do
    scope = FileResource.is_pdf.where("file_data->'metadata'->>'filename' LIKE ?", 'AccessibleCopy_%')

    puts "Found #{scope.count} FileResource records with AccessibleCopy_ filename prefix"

    scope.find_each do |file_resource|
      file_resource.update(remediated_version: true)

      latest_work_version = file_resource.work_versions.order(:version_number).last ||
        file_resource.work_versions.order(:created_at).last

      latest_work_version.update(remediated_version: true)

      puts "Flagged WorkVersion ##{latest_work_version.id} and FileResource ##{file_resource.id} as remediated_version"
    end
  end
end
