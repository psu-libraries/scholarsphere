# frozen_string_literal: true

Bugsnag.configure do |config|
  release_stage = ENV.fetch('BUGSNAG_RELEASE_STAGE', 'development')
  config.app_version = ENV.fetch('APP_VERSION', nil)
  config.release_stage = release_stage

  config.discard_classes << 'ActionController::UnknownFormat'

  unless release_stage == 'ulprod'
    config.discard_classes << 'Shrine::FileNotFound'
  end

  config.add_on_error(proc do |event|
    action = event.request&.dig(:railsAction)

    event.ignore! if action&.start_with?('ok_computer')
  end)
end
