# frozen_string_literal: true

class SolrIndexingJob < ApplicationJob
  queue_as :indexing

  def perform(indexable_resource, commit: true)
    indexable_resource.update_index(commit: commit)
  end
end
