# frozen_string_literal: true

class CollectionDecorator < ResourceDecorator
  def work_versions_for_display
    works
      .includes(versions: :creator_aliases)
      .map(&:latest_published_version)
      .compact
      .map do |work_version|
        SolrDocumentAdapterDecorator.new(
          WorkVersionDecorator.new(work_version)
        )
      end
  end
end
