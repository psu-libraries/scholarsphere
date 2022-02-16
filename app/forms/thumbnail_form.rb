# frozen_string_literal: true

class ThumbnailForm
  include ActiveModel::Model

  attr_reader :resource

  def initialize(resource:, params:)
    @resource = resource
    super(params)
  end

  def auto_generate_thumbnail
    @auto_generate_thumbnail ||= resource.auto_generate_thumbnail
  end

  def auto_generate_thumbnail=(auto_generate_thumbnail)
    @auto_generate_thumbnail = auto_generate_thumbnail
  end

  def thumbnail_upload=(thumbnail_upload)
    resource.thumbnail_upload.destroy! if resource.thumbnail_upload.present?

    tu = ThumbnailUpload.new resource: resource
    tu.attributes = { file_resource_attributes: { file: JSON.parse(thumbnail_upload) } }
    tu.file_resource.save
    tu.save
  end

  def _destroy=(_destroy)
    resource.thumbnail_upload.destroy! if _destroy == "true"
  end

  def save
    resource.auto_generate_thumbnail = @auto_generate_thumbnail
    return false if errors.present?

    resource.save
  end
end
