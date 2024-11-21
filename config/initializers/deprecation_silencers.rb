# frozen_string_literal: true

# Silence deprecation warnings made in the deprecation gem and in active-support

if ENV['RAILS_ENV'] == 'production'
  Deprecation.default_deprecation_behavior = :silence
  ActiveSupport::Deprecation.disallowed_behavior = [:silence]
end
