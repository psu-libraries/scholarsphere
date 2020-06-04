# frozen_string_literal: true

module HealthChecks
  class QueueLatencyCheck < OkComputer::Check
    attr_accessor :threshold

    def initialize(threshold = 30)
      self.threshold = threshold.to_i
    end

    def check
      @failures = nil
      @message = Hash.new
      queues = Sidekiq::Queue.all
      queues.each do |q|
        latency(q.name, threshold)
      end

      mark_failure if @failures
      mark_message @message
    end

    def latency(queue, threshold)
      queue_latency = Sidekiq::Queue.new(queue).latency
      @message[queue] = "has a latency of #{queue_latency} seconds"
      @failures = true if queue_latency > threshold
    end
  end
end
