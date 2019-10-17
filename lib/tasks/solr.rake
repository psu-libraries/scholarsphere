# frozen_string_literal: true

require 'solr_configurator'

namespace :solr do
  desc 'Solr tasks'
  task delete: :environment do
  end

  task init: :environment do
    conf = SolrConfigurator.new
    conf.upload_config unless conf.configset_exists?
    conf.create_collection unless conf.collection_exists?
    # we always modify collection. it's call is idempotent, and
    # will ensure we have the config bound to the collection
    conf.modify_collection
  end
end
