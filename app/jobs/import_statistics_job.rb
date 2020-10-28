# frozen_string_literal: true

class ImportStatisticsJob < ApplicationJob
  ImportStatistic = Struct.new(:pid, :timestamp, :views)

  queue_as :statistics

  def perform(row)
    import_stat = ImportStatistic.new(*row)
    id = LegacyIdentifier.find_by(old_id: import_stat.pid)
    return if id.nil?

    resource = id.resource

    if resource.is_a?(Work)
      work_version = resource.latest_published_version
      return if work_version.nil?

      work_version.view_statistics.find_or_create_by(date: import_stat.timestamp, count: import_stat.views)
    else
      resource.view_statistics.find_or_create_by(date: import_stat.timestamp, count: import_stat.views)
    end
  end
end
