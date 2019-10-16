# frozen_string_literal: true

require 'solr_configurator'

namespace :solr do
  desc 'Solr tasks'
  task delete: :environment do
  end

  task init: :environment do
    configurator = SolrConfigurator.new

    configurator.upload_config
    configurator.create_collection
    configurator.modify_collection
  end
end
