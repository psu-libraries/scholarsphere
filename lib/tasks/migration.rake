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

  # TODO: This can be deleted after it is done (if we decide to use it)
  desc "Set Work and Collection's #thumbnail_selection to #{ThumbnailSelections::AUTO_GENERATED}
        if an #auto_generated_thumbnail_url is present"
  task set_thumbnail_selections: :environment do
    Work.find_each do |w|
      w.update(thumbnail_selection: ThumbnailSelections::AUTO_GENERATED) if w.auto_generated_thumbnail_url.present?
    end

    Collection.find_each do |c|
      c.update(thumbnail_selection: ThumbnailSelections::AUTO_GENERATED) if c.auto_generated_thumbnail_url.present?
    end
  end
end
