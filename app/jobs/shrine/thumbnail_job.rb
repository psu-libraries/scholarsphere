# frozen_string_literal: true

class Shrine::ThumbnailJob < ApplicationJob
  queue_as :thumbnails

  def perform(file_resource_id:)
    record = FileResource.find(file_resource_id)
    record.with_lock do
      attacher = record.file_attacher
      attacher.create_derivatives :thumbnail
      record.save
    end
  rescue Shrine::AttachmentChanged, ActiveRecord::RecordNotFound
    # attachment has changed or record has been deleted, nothing to do
  end
end
