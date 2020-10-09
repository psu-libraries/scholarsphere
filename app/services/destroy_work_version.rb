# frozen_string_literal: true

class DestroyWorkVersion
  def self.call(work_version)
    parent_work = work_version.work

    if parent_work.versions.count == 1
      parent_work.destroy!
      IndexingService.delete_document(work_version.uuid, commit: true)
    else
      work_version.destroy!
      parent_work.reload
      IndexingService.delete_document(work_version.uuid, commit: false)
      WorkIndexer.call(parent_work, commit: true)
    end
  end
end
