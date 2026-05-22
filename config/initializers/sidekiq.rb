# frozen_string_literal: true

Sidekiq.configure_server do |config|
  config.redis = Rails.configuration.redis
  config.logger.formatter = Sidekiq::Logger::Formatters::JSON.new if Rails.env.production?
end

Sidekiq.configure_client do |config|
  config.redis = Rails.configuration.redis
  config.logger.formatter = Sidekiq::Logger::Formatters::JSON.new if Rails.env.production?
end
