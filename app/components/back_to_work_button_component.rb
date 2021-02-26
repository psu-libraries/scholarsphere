# frozen_string_literal: true

class BackToWorkButtonComponent < ApplicationComponent
  attr_reader :work

  def initialize(work:)
    @work = work
  end

  # If the work has not been published, that is if it _only_ has a draft version, then we want to go to the resource
  # page for that draft version.  If the work is withdrawn, or for some reason there's no draft version, we'll go to the
  # resource page for the first (likely withdrawn) version.  Otherwise, we want to to the resource page of the work
  # itself.
  def path
    resource = if work.latest_published_version.nil?
                 work.draft_version || work.versions[0]
               else
                 work
               end

    resource_path(resource.uuid)
  end
end
