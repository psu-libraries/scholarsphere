# frozen_string_literal: true

class SolrIndexingJob < ApplicationJob
  queue_as :default

  def perform(indexable_resource)
    indexable_resource.update_index
  end
end
