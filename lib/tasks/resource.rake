# frozen_string_literal: true

namespace :resource do
  desc 'Merge a collection into a single work + delete the original collection and its works'
  task :merge_and_delete_collection, [:uuid] => :environment do |_task, args|
    uuid = args[:uuid]

    result = MergeCollection.call(uuid)

    if result.successful?
      puts 'Collection merged successfully!'
    else
      result.errors.each do |err|
        puts err
      end
    end
  end

  desc 'Merge a collection into a single work without deleting the original collection'
  task :merge_collection, [:uuid] => :environment do |_task, args|
    uuid = args[:uuid]

    result = MergeCollection.call(uuid, delete_collection: false)

    if result.successful?
      puts 'Collection merged successfully!'
    else
      result.errors.each do |err|
        puts err
      end
    end
  end
end
