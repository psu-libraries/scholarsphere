# frozen_string_literal: true

class LatestPublishedVersionSchema < BaseSchema
  def document
    return {} unless resource.respond_to?(:latest_published_version)

    DefaultSchema.new(resource: resource.latest_published_version).document
  end
end
