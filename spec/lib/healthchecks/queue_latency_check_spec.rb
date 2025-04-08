# frozen_string_literal: true

require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe HealthChecks::QueueLatencyCheck, :sidekiq do
  let(:queue_name) { "#{Rails.configuration.active_job.queue_name_prefix}_test_queue" }

  before(:all) do
    class TestJob < ApplicationJob
      queue_as :test_queue

      def perform
        true
      end
    end
  end

  after(:all) do
    Object.send(:remove_const, 'TestJob') if Object.const_defined?(:TestJob)
  end

  before do
    Sidekiq::Queue.all.map(&:clear)
    TestJob.perform_later
  end

  after { Sidekiq::Queue.all.map(&:clear) }

  describe '#check' do
    context 'when latency is fine' do
      it 'returns no failure' do
        hc = described_class.new
        hc.check
        expect(hc.failure_occurred).to be nil
      end

      it 'writes a message' do
        hc = described_class.new
        hc.check
        expect(hc.message[queue_name]).to match(/has a latency of \d.+ seconds/)
      end
    end

    context 'when latency exceeds the threshold' do
      it 'returns a failure' do
        hc = described_class.new(-1)
        hc.check
        expect(hc.failure_occurred).to be true
      end
    end
  end
end
