# frozen_string_literal: true

class WorkPublishedWebhookJob < ApplicationJob
  queue_as :webhooks

  def perform(work_uuid)
    WorkPublishedWebhook.new(work_uuid).notify
  end
end
