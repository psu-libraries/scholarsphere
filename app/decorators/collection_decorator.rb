# frozen_string_literal: true

class CollectionDecorator < ResourceDecorator
  def decorated_work_versions
    works
      .includes(versions: :creators)
      .map(&:latest_published_version)
      .reject(&:blank?)
      .map do |work_version|
        SolrDocumentAdapterDecorator.new(
          WorkVersionDecorator.new(work_version)
        )
      end
  end
end
