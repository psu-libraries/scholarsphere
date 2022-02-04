# frozen_string_literal: true

class Shrine::PromotionJob < ApplicationJob
  queue_as :shrine

  def perform(record:, name:, file_data:)
    allowed_thumbnail_mime_types = ['application/pdf']
    attacher = Shrine::Attacher.retrieve(model: record, name: name.to_sym, file: file_data)
    attacher.atomic_promote
    if allowed_thumbnail_mime_types.include?(record.metadata['mime_type'])
      Shrine::ThumbnailJob.perform_later(record)
    end
  rescue Shrine::AttachmentChanged, ActiveRecord::RecordNotFound
    # attachment has changed or record has been deleted, nothing to do
  end
end
