# frozen_string_literal: true

module HealthChecks
  class QueueDeadSetCheck < OkComputer::Check
    def check
      ds = Sidekiq::DeadSet.new
      size = ds.size
      mark_failure if size.positive?
      mark_message "There are #{size} messages in the DeadSet Queue"
    end
  end
end
