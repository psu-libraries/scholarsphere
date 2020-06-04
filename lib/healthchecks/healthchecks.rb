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

  class QueueLatencyCheck < OkComputer::Check
    attr_accessor :threshold

    def initialize(threshold = 30)
      self.threshold = Integer(threshold)
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
