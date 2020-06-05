# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'
require 'okcomputer'
require 'healthchecks'
require 'scholarsphere/redis_config'

RSpec.describe HealthChecks::QueueLatencyCheck do
  before do
    Sidekiq::Testing.disable!
    redis_config = Scholarsphere::RedisConfig.new
    Sidekiq.configure_server do |config|
      config.redis = redis_config.to_hash
    end

    Sidekiq.configure_client do |config|
      config.redis = redis_config.to_hash
    end
  end

  describe '#check' do
    context 'when latency is fine' do
      it 'returns no failure' do
        hc = described_class.new
        hc.check
        expect(hc.failure_occurred).to be nil
      end
    end
  end
end
