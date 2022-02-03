# frozen_string_literal: true

class Shrine::ThumbnailJob < ApplicationJob
  queue_as :shrine

  def perform(record)
    attacher = record.file_attacher
    attacher.create_derivatives
    record.save
  rescue Shrine::AttachmentChanged, ActiveRecord::RecordNotFound
    # attachment has changed or record has been deleted, nothing to do
  end
end
