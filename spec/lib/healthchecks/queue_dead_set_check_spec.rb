# frozen_string_literal: true

require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe HealthChecks::QueueDeadSetCheck, :sidekiq do
  before { Sidekiq::DeadSet.new.clear }

  describe '#check' do
    context 'when there are no messages in deadset' do
      it 'returns no failure' do
        hc = described_class.new
        hc.check
        expect(hc.failure_occurred).to be_nil
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
