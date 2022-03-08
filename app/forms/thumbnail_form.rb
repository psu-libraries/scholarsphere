# frozen_string_literal: true

class ThumbnailForm
  include ActiveModel::Model

  attr_reader :resource

  def initialize(resource:, params:)
    @resource = resource
    super(params)
  end

  def thumbnail_upload
    @thumbnail_upload.presence
  end

  def thumbnail_upload=(thumbnail_upload)
    @thumbnail_upload = thumbnail_upload
  end

  def thumbnail_selection
    @thumbnail_selection ||= resource.thumbnail_selection
  end

  def thumbnail_selection=(thumbnail_selection)
    @thumbnail_selection = thumbnail_selection
  end

  def save
    ActiveRecord::Base.transaction do
      resource.thumbnail_selection = thumbnail_selection

      save_thumbnail_upload
    end
    return false if errors.present?

    resource.save
  end

  private

    def save_thumbnail_upload
      if thumbnail_upload.present?
        resource.thumbnail_upload.destroy! if resource.thumbnail_upload.present?

        tu = ThumbnailUpload.new resource: resource
        tu.attributes = { file_resource_attributes: { file: thumbnail_upload } }
        tu.file_resource.save
        tu.save
      end
    end
end
