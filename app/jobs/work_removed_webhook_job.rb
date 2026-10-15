# frozen_string_literal: true

class WorkRemovedWebhookJob < ApplicationJob
  queue_as :webhooks

  def perform(work_uuid)
    Webhooks::WorkRemovedWebhook.new(work_uuid).notify
  end
end
