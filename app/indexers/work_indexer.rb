# frozen_string_literal: true

class WorkIndexer
  def self.call(work, commit: false)
    work.versions.published.map do |version|
      IndexingService.add_document(version.to_solr, commit: false)
    end
    IndexingService.add_document(work.to_solr, commit: commit)
  end
end
