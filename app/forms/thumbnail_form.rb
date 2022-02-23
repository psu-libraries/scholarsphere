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

  def thumbnail_upload
    return nil if @thumbnail_upload.blank?

    JSON.parse(@thumbnail_upload)
  end

  def thumbnail_upload=(thumbnail_upload)
    @thumbnail_upload = thumbnail_upload
  end

  def _destroy
    @_destroy == 'true'
  end

  def _destroy=(_destroy)
    @_destroy = _destroy
  end

  def save
    if _destroy
      resource.thumbnail_upload.destroy!
    else
      resource.auto_generate_thumbnail = auto_generate_thumbnail

      if thumbnail_upload.present?
        resource.thumbnail_upload.destroy! if resource.thumbnail_upload.present?

        tu = ThumbnailUpload.new resource: resource
        tu.attributes = { file_resource_attributes: { file: thumbnail_upload } }
        tu.file_resource.save
        tu.save
      end
    end

    return false if errors.present?

    resource.save
  end
end
