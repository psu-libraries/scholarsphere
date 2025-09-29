require 'down'

class BuildAutoRemediatedWorkVersion
  def self.call(file_resource, remediated_file_url)
    version_being_remediated = file_resource.work_versions.where.not(work_versions: { auto_remediation_started_at: nil }).last

    ActiveRecord::Base.transaction do
      if file_resource.work_versions.where("work_versions.id > ? AND auto_remediated_version = ?", version_being_remediated.id, true).exists?
        new_version = file_resource.work_versions.where(auto_remediated_version: true).last
      else
        new_version = BuildNewWorkVersion.call(version_being_remediated)
        new_version.update auto_remediated_version: true
      end
      replacement_tempfile = Down.download(remediated_file_url)
      version_file_link_to_delete = new_version.file_version_memberships.find_by(file_resource: file_resource)
      version_file_link_to_delete.destroy!
      new_version.file_resources.create!(
        file: replacement_tempfile,
        auto_remediated_version: true
      )

      if new_version.file_resources.where('file_resources.remediation_job_uuid IS NOT NULL AND file_resources.auto_remediated_version = ?', false).exists?
        new_version.save!
      else
        new_version.publish!
      end
      new_version
    end
  end
end
