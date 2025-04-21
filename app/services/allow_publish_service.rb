# frozen_string_literal: true

class AllowPublishService
  def initialize(resource)
    @resource = resource
  end

  def allow?(current_user: nil)
    if Work::Types.all.include?(resource.work_type)
      (!resource.draft_curation_requested &&
        !resource.accessibility_remediation_requested &&
        resource.file_version_memberships.none?(&:accessibility_score_pending?)) || !!current_user&.admin?
    else
      true
    end
  end

  private

    attr_reader :resource
end
