# frozen_string_literal: true

module AuthorshipMigration
  class CollectionAuthorshipPositionFix
    class << self
      def call
        errors = []

        Collection.find_each do |collection|
          update_collection_authorships(collection)
        rescue StandardError => e
          errors << "Collection##{collection.id}, #{e.message}"
        end

        errors.each { |e| puts e }
        errors.empty?
      end

      def update_collection_authorships(collection)
        return unless all_empty?(collection.creators)

        collection.creators.sort_by(&:id).each_with_index do |authorship, index|
          authorship.update(position: (index + 1) * 10, changed_by_system: true)
        end
      end

      def all_empty?(authorships)
        positions = authorships.map(&:position).uniq

        if positions.length > 1 && positions.any?(nil)
          raise StandardError, "can't be corrected"
        else
          positions == [nil]
        end
      end
    end
  end
end
