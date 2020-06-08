# frozen_string_literal: true

module HealthChecks
  class QueueLatencyCheck < OkComputer::Check
    attr_reader :threshold

    def initialize(threshold = 30)
      @threshold = threshold.to_i
    end

    def check
      @failures = nil
      @message = Hash.new
      Sidekiq::Queue.all.map do |q|
        queue_latency = Sidekiq::Queue.new(q.name).latency
        @message[q.name] = "has a latency of #{queue_latency} seconds"
        mark_failure if queue_latency > threshold
      end
    end
  end
end
