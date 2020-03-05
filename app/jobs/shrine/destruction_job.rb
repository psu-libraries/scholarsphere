# frozen_string_literal: true

class Shrine::DestructionJob < ApplicationJob
  queue_as :shrine

  def perform(data:)
    attacher = FileUploader::Attacher.from_data(data)
    attacher.destroy
  end
end
