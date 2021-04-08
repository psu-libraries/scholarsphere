# frozen_string_literal: true

class LatestPublishedVersionSchema < BaseSchema
  def document
    return {} unless resource.respond_to?(:latest_published_version)

    DefaultSchema.new(resource: resource.latest_published_version)
      .document
      .merge(creator_schema.document)
      .merge(published_date_schema.document)
      .merge(facet_schema.document)
      .merge(title_schema.document)
  end

  private

    def creator_schema
      CreatorSchema.new(resource: resource.latest_published_version)
    end

    def published_date_schema
      PublishedDateSchema.new(resource: resource.latest_published_version)
    end

    def facet_schema
      FacetSchema.new(resource: resource.latest_published_version)
    end

    def title_schema
      TitleSchema.new(resource: resource.latest_published_version)
    end
end
