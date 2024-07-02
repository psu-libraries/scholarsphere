# frozen_string_literal: true

Bugsnag.configure do |config|
  config.app_version = ENV.fetch('APP_VERSION', nil)
  config.release_stage = ENV.fetch('BUGSNAG_RELEASE_STAGE', 'development')
end
