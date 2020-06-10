# frozen_string_literal: true

module MetadataListener
  class Job < ApplicationJob
    queue_as :metadata

    ## Job is performed by metadata-listener
    def perform(**args)
    end
  end
end
