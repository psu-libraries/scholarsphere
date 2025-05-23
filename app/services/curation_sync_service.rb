# frozen_string_literal: true

class CurationSyncService
  def initialize(work)
    @work = work
  end

  def sync
    retries ||= 0
    tasks = CurationTaskClient.find_all(@work.id)
    task_uuids = tasks.pluck('ID')

    if task_uuids.exclude?(current_version_for_curation.uuid) && !admin_submitted?(current_version_for_curation)
      CurationTaskClient.send_curation(current_version_for_curation.id, updated_version: updated_version(tasks))
    end
  rescue CurationTaskClient::CurationError => e
    retry if (retries += 1) < 3 && e.message.match(/5[0-9][0-9]/)

    Rails.logger.error(e)
  end

  private

    def current_version_for_curation
      if @work.latest_version.draft_curation_requested == true
        @work.latest_version
      else
        @work.latest_published_version
      end
    end

    def updated_version(tasks)
      stale_version = false
      tasks.each do |task|
        stale_version = true unless task.fields['ID'] == current_version_for_curation.uuid
      end
      stale_version
    end

    def admin_submitted?(work_version)
      publishing_changes = work_version.versions.select { |v| v.object_changes['published_at'].present? }
      whodunnit = publishing_changes.last['whodunnit']
      user = GlobalID::Locator.locate(whodunnit)
      user.is_a?(User) && user&.admin?
    rescue StandardError
      false
    end
end
