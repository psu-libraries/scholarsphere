# frozen_string_literal: true

require 'rails_helper'

# At the moment, there was a bug in Rails that did not let you override the
# queue adapter. It's unclear whether that bug is solved or not, so in the mean
# time this test is here to ensure nothing breaks or needs to be updated when we
# upgrade to future releases of Rails.

RSpec.describe 'Can change the queue adapter', :inline_jobs do
  before(:all) do
    class TestJob < ApplicationJob
      cattr_accessor :job_ran

      def perform
        @@job_ran = true
      end
    end
  end

  after(:all) do
    Object.send(:remove_const, :TestJob) if Object.const_defined?(:TestJob)
  end

  before { driven_by(:rack_test) }

  describe '#perform_later' do
    it 'perform later TestJob' do
      expect(ActiveJob::Base.queue_adapter).to be_an_instance_of(ActiveJob::QueueAdapters::InlineAdapter)

      TestJob.perform_later

      expect(TestJob.job_ran).to eq(true)
    end
  end
end
