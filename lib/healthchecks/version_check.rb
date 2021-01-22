# frozen_string_literal: true

module HealthChecks
  class VersionCheck < OkComputer::Check
    def check
      version = ENV.fetch('APP_VERSION', 'unknown')
      mark_message version.to_s
    end
  end
end
