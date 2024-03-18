# frozen_string_literal: true

class CurationSyncService
  def initialize(work)
    @work = work
    @tasks = CurationTaskClient.find_all(@work.id)
  end

  def sync
    task_uuids = @tasks.pluck('ID')

    if task_uuids.exclude?(current_version_for_curation.uuid)
      CurationTaskClient.send_curation(current_version_for_curation.id, updated_version: updated_version)
    end
  end

  private

    def current_version_for_curation
      if @work.latest_version.draft_curation_requested == true
        @work.latest_version
      else
        @work.latest_published_version
      end
    end

    def updated_version
      stale_version = false
      @tasks.each do |task|
        stale_version = true unless task.fields['ID'] == current_version_for_curation.uuid
      end
      stale_version
    end
end
