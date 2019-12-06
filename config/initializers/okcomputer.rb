# frozen_string_literal: true

require 'scholarsphere/redis_config'

redis_config = Scholarsphere::RedisConfig.new

OkComputer.mount_at = false

OkComputer::Registry.register 'solr', OkComputer::SolrCheck.new(Rails.application.config_for(:blacklight)[:url])

OkComputer::Registry.register 'redis', OkComputer::RedisCheck.new(redis_config.to_hash) if redis_config.valid?
