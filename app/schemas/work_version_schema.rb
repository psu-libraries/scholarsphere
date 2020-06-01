# frozen_string_literal: true

class WorkVersionSchema < BaseSchema
  def document
    DefaultSchema.new(resource: resource)
      .document
      .merge(
        latest_version_bsi: resource.latest_published_version?
      )
  end
end
