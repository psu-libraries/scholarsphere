# frozen_string_literal: true

class WorkVersions::VersionNavigationDropdownComponent < ApplicationComponent
  include Rails.application.routes.url_helpers

  def initialize(work:, current_version:)
    @work = work
    @current_version = current_version
  end

  private

    attr_reader :work,
                :current_version

    def drop_down_menu_options
      work.decorated_versions.reverse.map do |version|
        [
          version,
          path_for(version),
          classes_for(version)
        ]
      end
    end

    def path_for(version)
      if work.latest_published_version.uuid == version.uuid
        resource_path(work.uuid)
      else
        resource_path(version.uuid)
      end
    end

    def classes_for(version)
      classes = []
      classes << 'disabled' if current?(version)
      classes.join(' ')
    end

    def current?(version)
      current_version.uuid == version.uuid
    end
end
