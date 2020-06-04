# frozen_string_literal: true

redis_config = Scholarsphere::RedisConfig.new

OkComputer.mount_at = false

OkComputer::Registry.register 'solr', OkComputer::SolrCheck.new(Rails.application.config_for(:blacklight)[:url])

## When we have a valid redis configuration, we register
## sidekiq and redis checks
if redis_config.valid?
  OkComputer::Registry.register 'redis', OkComputer::RedisCheck.new(redis_config.to_hash)
  OkComputer::Registry.register 'sidekiq', HealthChecks::QueueLatencyCheck.new(threshold = ENV.fetch('SIDEKIQ_QUEUE_LATENCY_THRESHOLD', 30).to_i)
  OkComputer::Registry.register 'sidekiq_deadset', HealthChecks::QueueDeadSetCheck.new
  # Reports as Failed, but continues to return 200 status code.
  # This is so a POD won't get restarted just for latency checks.
  OkComputer.make_optional %w(sidekiq sidekiq_deadset)
end
