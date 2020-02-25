# frozen_string_literal: true

class LatestPublishedVersionSchema < BaseSchema
  def document
    return {} unless resource.respond_to?(:latest_published_version)

    DefaultSchema.new(resource: resource.latest_published_version)
      .document
      .merge(creator_schema.document)
  end

  private

    def creator_schema
      CreatorSchema.new(resource: resource.latest_published_version)
    end
end
