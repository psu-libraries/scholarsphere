# frozen_string_literal: true

class CurationSyncService
  def initialize(work)
    @work = work
  end

  def sync
    retries ||= 0
    tasks = CurationTaskClient.find_all(@work.id)
    task_uuids = tasks.pluck('ID')

    if task_uuids.exclude?(current_version_for_curation.uuid)
      CurationTaskClient.send_curation(current_version_for_curation.id, updated_version: updated_version(tasks)) unless admin_submitted?(current_version_for_curation)
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
      true
    #   publishing_changes = wv.versions.select { |v| v.object_changes['published_at'].present? }
    #   whodunnit = publishing_changes.last['whodunnit']
    #   user_id = /\d+/.match(whodun).to_a.first
    #   user = User.find(user_id)
    #   user&.admin?

    # rescue
    #   false
    end
end
