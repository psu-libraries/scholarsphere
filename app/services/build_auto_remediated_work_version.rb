# frozen_string_literal: true

require 'down'

class BuildAutoRemediatedWorkVersion
  class NotNewestReleaseError < StandardError; end

  def self.call(file_resource, remediated_file_url)
    wv_being_remediated = file_resource.latest_remediation_work_version_candidate
    original_filename = file_resource.file_data['metadata']['filename']
    # In the rare case a new work version is published after the remediation
    # job started, we stop the creation of a new remediated version here.
    unless wv_being_remediated.latest_published_version?
      file_resource.first_auto_remediated_work_version_after(wv_being_remediated)&.destroy!
      raise NotNewestReleaseError, 'A newer published version exists.  A remediated version will not be created.'
    end

    PaperTrail.request(whodunnit: ExternalApp.pdf_accessibility_api.to_global_id.to_s) do
      ActiveRecord::Base.transaction do
        built_work_version = file_resource.first_auto_remediated_work_version_after(wv_being_remediated) ||
          begin
            v = BuildNewWorkVersion.call(wv_being_remediated)
            v.update({ auto_remediated_version: true,
                       external_app: ExternalApp.pdf_accessibility_api })
            v
          end

        fvm_to_destroy = built_work_version.file_version_memberships
          .find_by(file_resource: file_resource)
        fvm_to_destroy&.destroy!

        replacement_tempfile = Down.download(remediated_file_url)
        build_file_resource(built_work_version, replacement_tempfile, original_filename)
        if built_work_version.has_remaining_auto_remediation_jobs?
          built_work_version.save!
        else
          built_work_version.publish!
          AutoRemediationNotifications.new(built_work_version).send_notifications
        end

        return built_work_version
      end
    end
  end

  def self.build_file_resource(work_version, replacement_tempfile, original_filename)
    new_resource = work_version.file_resources.create!(
      file: replacement_tempfile,
      auto_remediated_version: true
    )

    new_resource.file_data['metadata']['filename'] = "ACCESSIBLE_VERSION_#{original_filename}"
    new_resource.save!
  end
end
