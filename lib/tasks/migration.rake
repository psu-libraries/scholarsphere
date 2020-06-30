# frozen_string_literal: true

require 'csv'

namespace :migration do
  ImportStatistic = Struct.new(:pid, :timestamp, :views)

  desc 'Import statistics from Scholarsphere 3'
  task :statistics, [:file] => :environment do |_task, args|
    path = Rails.root.join(args[:file])
    CSV.foreach(path) do |row|
      import_stat = ImportStatistic.new(*row)
      id = LegacyIdentifier.find_by(old_id: import_stat.pid)
      next if id.nil?

      resource = id.resource

      if resource.is_a?(Work)
        work_version = resource.latest_published_version
        next if work_version.nil?

        work_version.view_statistics.find_or_create_by(date: import_stat.timestamp, count: import_stat.views)
      else
        resource.view_statistics.find_or_create_by(date: import_stat.timestamp, count: import_stat.views)
      end
    end
  end
end
