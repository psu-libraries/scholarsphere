# frozen_string_literal: true

class Shrine::PromotionJob < ApplicationJob
  queue_as :shrine

  def perform(record:, name:, file_data:)
    attacher = Shrine::Attacher.retrieve(model: record, name: name.to_sym, file: file_data)
    attacher.atomic_promote
    Shrine::ThumbnailJob.perform_later(record) if perform_thumbnail?(record)
  rescue Shrine::AttachmentChanged, ActiveRecord::RecordNotFound
    # attachment has changed or record has been deleted, nothing to do
  end

  def perform_thumbnail?(record)
    # we perform the thumbnail job if the mime_type is supported
    mime_type = record.file_data['metadata']['mime_type'] || ''
    return true if mime_type.include?('image')
    return true if mime_type == 'application/pdf'

    false
  end
end
