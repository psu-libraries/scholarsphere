# frozen_string_literal: true

module MetadataListener
  class Job
    # MetadataListener is not a Rails app, so do not use
    # ActiveJob.  Instead, use Sidekiq::Job directly.
    include Sidekiq::Job

    queue_as :metadata

    ## Job is performed by metadata-listener
    def perform(**args)
    end
  end
end
