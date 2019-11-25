# frozen_string_literal: true

class IndexingService
  # @param [Hash]
  # @param [Boolean]
  def self.add_document(document, commit: false)
    connection = Blacklight.default_index.connection
    connection.add(document)
    connection.commit if commit
  end

  def self.commit
    Blacklight.default_index.connection.commit
  end
end
