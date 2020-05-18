# frozen_string_literal: true

if ENV['DD_AGENT_HOST']
  require 'ddtrace'
  Datadog.configure do |c|
    c.use :rails
    c.use :active_record, orm_service_name: 'scholarsphere-active_record'
    c.use :faraday, service_name: 'scholarsphere-faraday'
    c.use :sidekiq, analytics_enabled: true
    c.use :redis
    c.tracer env: ENV['DD_ENV']
  end
end
