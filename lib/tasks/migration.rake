# frozen_string_literal: true

require 'csv'
require_relative '../../app/models/concerns/thumbnail_selections'

namespace :migration do
  desc 'Import statistics from Scholarsphere 3'
  task :statistics, [:file] => :environment do |_task, args|
    path = Rails.root.join(args[:file])
    CSV.foreach(path) do |row|
      ImportStatisticsJob.perform_later(row)
    end
  end
end
