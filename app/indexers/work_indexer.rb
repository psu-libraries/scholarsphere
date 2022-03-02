# frozen_string_literal: true

# @abstract Indexes a work and all of its versions, regardless of state.
#   * works are always indexed
#   * each work version is always indexed
#   * withdrawn versions are not removed

class WorkIndexer
  def self.call(work, commit: false, reload: false)
    work.reload if reload

    work.versions.map do |version|
      IndexingService.add_document(version.to_solr, commit: false)
    end

    work.collections.map do |collection|
      IndexingService.add_document(collection.to_solr, commit: false)
    end

    IndexingService.add_document(work.to_solr, commit: commit)
    Blacklight.default_index.connection.commit if commit
  end
end
