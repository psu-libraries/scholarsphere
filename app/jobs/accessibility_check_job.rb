# frozen_string_literal: true

class AccessibilityCheckJob < ApplicationJob
  queue_as :accessibility_check

  def perform(resource_id)
    resource = FileResource.find(resource_id)
    AdobePdf::AccessibilityChecker.new(resource).call
  rescue StandardError => e
    AccessibilityCheckResult.create!(file_resource: resource,
                                           detailed_report: { error: e.message })
    # Raise error so sidekiq registers the failure
    raise e
  end
end
