# frozen_string_literal: true

require 'down'

class BuildAutoRemediatedWorkVersion
  def self.call(file_resource, remediated_file_url)
    wv_being_remediated = file_resource.latest_remediation_work_version_candidate

    ActiveRecord::Base.transaction do
      new_work_version = file_resource.latest_auto_remediated_work_version_after(wv_being_remediated) ||
        begin
          v = BuildNewWorkVersion.call(wv_being_remediated)
          v.update(auto_remediated_version: true)
          v
        end

      fvm_to_destroy = new_work_version.file_version_memberships
        .find_by(file_resource: file_resource)
      fvm_to_destroy&.destroy!

      replacement_tempfile = Down.download(remediated_file_url)
      new_work_version.file_resources.create!(
        file: replacement_tempfile,
        auto_remediated_version: true
      )

      if new_work_version.has_remaining_auto_remediation_jobs?
        new_work_version.save!
      else
        new_work_version.publish!
      end

      new_work_version
    end
  end
end
