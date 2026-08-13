# frozen_string_literal: true

OkComputer.mount_at = false

OkComputer::Registry.register(
  'solr',
  OkComputer::SolrCheck.new(Rails.application.config_for(:blacklight)[:url])
)

OkComputer::Registry.register(
  'redis',
  OkComputer::RedisCheck.new(Rails.configuration.redis)
)

OkComputer::Registry.register(
  'sidekiq',
  Healthchecks::QueueLatencyCheck.new(ENV.fetch('SIDEKIQ_QUEUE_LATENCY_THRESHOLD', 30).to_i)
)

OkComputer::Registry.register(
  'sidekiq_deadset',
  Healthchecks::QueueDeadSetCheck.new
)

OkComputer::Registry.register(
  'version',
  Healthchecks::VersionCheck.new
)

OkComputer::Registry.register(
  'dois',
  Healthchecks::Dois.new(ENV.fetch('DRAFT_DOI_THRESHOLD', 0).to_i)
)

# Reports as Failed, but continues to return 200 status code.
# This is so a POD won't get restarted just for optional checks.
OkComputer.make_optional %w(sidekiq sidekiq_deadset version)
