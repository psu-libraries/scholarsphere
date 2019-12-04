# frozen_string_literal: true

require 'scholarsphere/redis_config'

redis_config = Scholarsphere::RedisConfig.new.call

Sidekiq.configure_server do |config|
  config.redis = redis_config
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end
