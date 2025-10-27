# frozen_string_literal: true

require 'down'

class BuildAutoRemediatedWorkVersion
  class NotNewestReleaseError < StandardError; end

  def self.call(file_resource, remediated_file_url)
    wv_being_remediated = file_resource.latest_remediation_work_version_candidate

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
        built_work_version.file_resources.create!(
          file: replacement_tempfile,
          auto_remediated_version: true
        )

        if built_work_version.has_remaining_auto_remediation_jobs?
          built_work_version.save!
        else
          on_publish(built_work_version)
        end

        return built_work_version
      end
    end
  end

  def self.on_publish(built_work_version)
    built_work_version.publish!
    lib_answers = LibanswersApiService.new
    lib_answers.admin_create_ticket(built_work_version.work.id, 'work_remediation')
    AutoRemediationNotifications.new(built_work_version).send_notifications
  end
end
