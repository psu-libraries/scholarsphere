# frozen_string_literal: true

class OpenAccessVersionGuesserJob < ApplicationJob
  queue_as :default

  def perform(work_version_id)
    work_version = WorkVersion.find(work_version_id)
    version = OpenAccessVersion::Guesser.new(work_version: work_version).version

    update_open_access_version_if_undetermined(work_version, version)
  rescue StandardError => e
    update_open_access_version_if_undetermined(work_version, OpenAccessVersion::VersionValues::UNKNOWN)
    raise e
  end

  private

    def update_open_access_version_if_undetermined(work_version, version)
      work_version.with_lock do
        work_version.reload
        work_version.update!(open_access_version: version) if work_version.open_access_version.blank?
      end
    end
end
