# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'
require 'okcomputer'
require 'healthchecks'
require 'scholarsphere/redis_config'

RSpec.describe HealthChecks::QueueDeadSetCheck do
  before do
    Sidekiq::Testing.disable!
    redis_config = Scholarsphere::RedisConfig.new
    Sidekiq.configure_server do |config|
      config.redis = redis_config.to_hash
    end

    Sidekiq.configure_client do |config|
      config.redis = redis_config.to_hash
    end

    ds = Sidekiq::DeadSet.new
    ds.clear
  end

  describe '#check' do
    context 'when there are no messages in deadset' do
      it 'returns no failure' do
        hc = described_class.new
        hc.check
        expect(hc.failure_occurred).to be nil
      end
    end

    context 'when there are messages in deadset' do
      before do
        serialized_job = Sidekiq.dump_json(jid: '123123', class: 'SomeWorker', args: [])
        ds = Sidekiq::DeadSet.new
        ds.kill(serialized_job)
      end

      it 'returns a failure' do
        hc = described_class.new
        check = hc.check
        expect(hc.failure_occurred).to be true
        expect(check).to eq 'There are 1 messages in the DeadSet Queue'
      end
    end
  end
end
