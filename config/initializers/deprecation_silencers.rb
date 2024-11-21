# frozen_string_literal: true

# Silence deprecation warnings made in the deprecation gem

if ENV['RAILS_ENV'] == 'production'
  Deprecation.default_deprecation_behavior = :silence
end
