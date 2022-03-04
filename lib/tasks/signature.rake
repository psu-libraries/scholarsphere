# frozen_string_literal: true

namespace :signature do
  desc 'Calculate file signatures for FileResources missing signatures'
  task missing: :environment do |_task|
    FileResource.where.not("file_data->'metadata' ?| array[:keys]", keys: ['sha256', 'md5']).each do |file_resource|
      puts "Performing Signature Job for FileResource(#{file_resource.id})"
      Shrine::SignatureJob.perform_later(file_resource_id: file_resource.id)
    end
  end

  desc 'Calculate file signatures for all FileResources'
  task all: :environment do |_task|
    FileResource.all.each do |file_resource|
      puts "Performing Signature Job for FileResource(#{file_resource.id})"
      Shrine::SignatureJob.perform_later(file_resource_id: file_resource.id)
    end
  end
end
