# frozen_string_literal: true

redis_config = Scholarsphere::RedisConfig.new

Sidekiq.configure_server do |config|
  config.redis = redis_config.to_hash
end

Sidekiq.configure_client do |config|
  config.redis = redis_config.to_hash
end
