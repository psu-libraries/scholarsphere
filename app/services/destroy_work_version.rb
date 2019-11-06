# frozen_string_literal: true

class DestroyWorkVersion
  def self.call(work_version)
    parent_work = work_version.work

    if parent_work.versions.count == 1
      parent_work.destroy!
    else
      work_version.destroy!
    end
  end
end
