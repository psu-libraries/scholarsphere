# frozen_string_literal: true

OkComputer.mount_at = false

OkComputer::Registry.register 'solr', OkComputer::SolrCheck.new(Rails.application.config_for(:blacklight)[:url])
