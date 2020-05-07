# frozen_string_literal: true

class CollectionIndexer
  def self.call(collection, commit: false)
    IndexingService.add_document(collection.to_solr, commit: commit)
  end
end
