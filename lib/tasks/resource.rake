# frozen_string_literal: true

namespace :resource do
  desc 'Merge a collection into a single work in draft state'
  task :merge_collection, [:uuid] => :environment do |_task, args|
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

  desc 'Force merge a collection into a single work in draft state'
  task :force_merge_collection, [:uuid] => :environment do |_task, args|
    uuid = args[:uuid]

    result = MergeCollection.call(uuid, force: true)

    if result.successful?
      puts 'Collection merged successfully!'
    else
      result.errors.each do |err|
        puts err
      end
    end
  end

  desc 'Deletes a collection and all its works'
  task :delete_collection, [:uuid] => :environment do |_task, args|
    uuid = args[:uuid]

    result = DeleteCollection.call(uuid)

    if result.successful?
      puts 'Collection deleted successfully'
    else
      result.errors.each do |err|
        puts err
      end
    end
  end
end
