# frozen_string_literal: true

module Indexing
  extend ActiveSupport::Concern

  included do
    attr_writer :indexing_source

    after_save :perform_update_index
  end

  def indexing_source
    @indexing_source ||= SolrIndexingJob.public_method(:perform_later)
  end

  private

    def perform_update_index
      indexing_source.call(self)
    end
end
