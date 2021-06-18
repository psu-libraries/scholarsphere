# frozen_string_literal: true

class UpdateWorkComponent < ApplicationComponent
  def initialize(work_version:, policy:)
    @work_version = work_version
    @policy = policy
  end

  def render
    true
  end

  private

    def path
      if @policy.new?
        # create a new draft work version
        dashboard_work_work_versions_path(@work_version.work)
      else
        # update the existing draft version
        dashboard_form_work_version_details_path(@work_version.id)
      end
    end

    def method
      return 'post' if @policy.new?
    end
end
