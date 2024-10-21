# frozen_string_literal: true

class AccessibilityCheckJob < ApplicationJob
  queue_as :accessibility_check

  def perform(resource_id)
    resource = FileResource.find(resource_id)
    AdobePdf::AccessibilityService.call(resource)
  rescue StandardError => e
    acr = AccessibilityCheckResult.find_or_initialize_by(file_resource: resource)
    acr.update!(report: { error: e.message })
    # Raise error so sidekiq registers the failure
    raise e
  end
end
