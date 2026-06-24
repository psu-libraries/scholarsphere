# frozen_string_literal: true

class CurationSyncService
  def initialize(work)
    @work = work
  end

  def sync
    retries ||= 0
    tasks = CurationTaskClient.find_all(@work.id)
    task_uuids = tasks.pluck('ID')
    work_version = current_version_for_curation

    if able_to_curate(task_uuids, work_version)
      CurationTaskClient.send_curation(work_version.id, updated_version: updated_version(tasks, work_version))
    end
  rescue CurationTaskClient::CurationError => e
    retry if (retries += 1) < 3 && e.message.match(/5[0-9][0-9]/)

    Rails.logger.error(e)
  end

  private

    def able_to_curate(task_uuids, work_version)
      work_version.present? &&
        task_uuids.exclude?(work_version.uuid) &&
        !admin_submitted?(work_version) &&
        work_version.sent_for_curation_at.nil? &&
        !work_version.remediated_version
    end

    def current_version_for_curation
      if @work.latest_version.draft_curation_requested == true
        @work.latest_version
      else
        @work.versions.published.where(remediated_version: false).last
      end
    end

    def updated_version(tasks, work_version)
      tasks.any? { |task| task.fields['ID'] != work_version.uuid }
    end

    def admin_submitted?(work_version)
      publishing_changes = work_version.versions.select { |v| v.object_changes['published_at'].present? }
      whodunnit = publishing_changes.last['whodunnit']
      user = GlobalID::Locator.locate(whodunnit)
      user.is_a?(User) && user.admin?
    rescue StandardError
      false
    end
end
