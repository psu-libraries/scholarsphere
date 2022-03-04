# frozen_string_literal: true

class Shrine::PromotionJob < ApplicationJob
  queue_as :shrine

  def perform(record:, name:, file_data:)
    attacher = Shrine::Attacher.retrieve(model: record, name: name.to_sym, file: file_data)
    attacher.atomic_promote
    Shrine::ThumbnailJob.perform_later(file_resource_id: record.id) if record.thumbnailable?
    Shrine::SignatureJob.perform_later(file_resource_id: record.id)
  rescue Shrine::AttachmentChanged, ActiveRecord::RecordNotFound
    # attachment has changed or record has been deleted, nothing to do
  end
end
