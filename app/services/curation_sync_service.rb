# frozen_string_literal: true

class CurationSyncService
  def self.sync(work_id)
    work = Work.find(work_id)
    tasks = CurationTaskClient.find_all(work_id)
    task_uuids = tasks.pluck('ID')

      #latest version might be a draft that is from curation in progress
    current_version_for_curation =
      if work.latest_version.draft_curation_requested == true
        work.latest_version
      else
        work.latest_published_version
      end

    if !task_uuids.include?(current_version_for_curation.uuid)
      CurationTaskClient.send_curation(current_version_for_curation.id) #if work.latest_published_version.curation_status == 'not started yet'
    end

    tasks.each do |task|
      CurationTaskClient.remove(task.id) unless task.fields["ID"] == current_version_for_curation.uuid
    end
  end

end