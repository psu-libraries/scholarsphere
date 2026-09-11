# frozen_string_literal: true

require 'fileutils'
require 'zip'

namespace :solr do
  desc 'Package solr configset into configset.zip'
  task package_configset: :environment do
    config_dir = 'solr/conf'
    zip_file = 'configset.zip'

    FileUtils.rm_f(zip_file)

    # Create zip
    Zip::File.open(zip_file, create: true) do |zip|
      Dir.glob("#{config_dir}/**/*").each do |file|
        next if File.directory?(file)

        zip.add(file.sub("#{config_dir}/", ''), file)
      end
    end

    puts "Created #{zip_file}"
  end
end
