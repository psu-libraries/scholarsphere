# frozen_string_literal: true

class SolrDeleteJob < ApplicationJob
  queue_as :indexing

  def perform(id)
    IndexingService.delete_document(id, commit: true)
  end
end
