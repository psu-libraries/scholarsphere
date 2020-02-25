# frozen_string_literal: true

class WorkVersionSchema < BaseSchema
  def document
    DefaultSchema.new(resource: resource)
      .document
      .merge(
        latest_version_bsi: resource.latest_published_version?,
        work_type_tesim: resource.work.work_type
      )
  end
end
