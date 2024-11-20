# frozen_string_literal: true

class IndexingService
  class << self
    # @param [Hash]
    # @param [Boolean]
    def add_document(document, commit: false)
      connection = Blacklight.default_index.connection
      connection.add(document)
      connection.commit if commit
    end

    # @param [String]
    # @param [Boolean]
    def delete_document(id, commit: false)
      connection = Blacklight.default_index.connection
      connection.delete_by_id(id)
      connection.commit if commit
    end

    def commit
      Blacklight.default_index.connection.commit
    end
  end
end
