# frozen_string_literal: true

class AllowPublishService
  def initialize(resource)
    @resource = resource
  end

  def allow?(current_user: nil)
    return true unless Work::Types.all.include?(resource.work_type)

    (!resource.draft_curation_requested &&
      !resource.accessibility_remediation_requested) || !!current_user&.admin?
  end

  private

    attr_reader :resource
end
