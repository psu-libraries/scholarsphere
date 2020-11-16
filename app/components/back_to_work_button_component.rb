# frozen_string_literal: true

class BackToWorkButtonComponent < ApplicationComponent
  attr_reader :work

  def initialize(work:)
    @work = work
  end

  # If the work has not been published, that is if it _only_ has a draft
  # version, then we want to go to the resource page for that draft version.
  # Otherwise, we want to to the resoure page of the work itself.
  def path
    resource = if work.latest_published_version.nil?
                 work.draft_version
               else
                 work
               end

    resource_path(resource.uuid)
  end
end
