# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'
require 'okcomputer'
require 'healthchecks'
require 'scholarsphere/redis_config'

RSpec.describe HealthChecks::QueueLatencyCheck, unless: !Scholarsphere::RedisConfig.new.valid? do
  let(:queue_name) { 'test_queue' }

  before(:all) do
    class TestJob < ApplicationJob
      queue_as :test_queue

      def perform
        true
      end
    end
  end

  after(:all) do
    ActiveSupport::Dependencies.remove_constant('TestJob')
  end

  before do
    Sidekiq::Testing.disable!
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
