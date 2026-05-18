# frozen_string_literal: true

class OpenAccessVersionGuesserJob < ApplicationJob
  queue_as :default

  def perform(work_version_id)
    work_version = WorkVersion.find(work_version_id)
    version = OpenAccessVersion::Guesser.new(work_version: work_version).version

    work_version.update!(open_access_version: version)
  end
end
