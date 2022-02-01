# frozen_string_literal: true

class Shrine::PromotionJob < ApplicationJob
  queue_as :shrine

  def perform(record:, name:, file_data:)
    attacher = Shrine::Attacher.retrieve(model: record, name: name.to_sym, file: file_data)
    begin
      attacher.create_derivatives
    rescue StandardError => e
      logger.error(e)
    end
    attacher.atomic_promote
  rescue Shrine::AttachmentChanged, ActiveRecord::RecordNotFound
    # attachment has changed or record has been deleted, nothing to do
  end
end
