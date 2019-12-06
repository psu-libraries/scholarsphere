# frozen_string_literal: true

require_relative 'boot'
require_relative '../lib/scholarsphere/redis_config'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_mailbox/engine'
require 'action_text/engine'
require 'action_view/railtie'
require 'action_cable/engine'
require 'sprockets/railtie'
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Scholarsphere
  class Application < Rails::Application
    config.generators { |generator| generator.test_framework :rspec }
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Active Job Configurations
    redis_config = Scholarsphere::RedisConfig.new

    if redis_config.valid?
      config.active_job.queue_adapter = :sidekiq
      # config.active_job.queue_name_prefix = "scholarsphere_production"
    else
      config.active_job.queue_adapter = :async
    end

    # Don't generate system test files.
    config.generators.system_tests = nil
  end
end
