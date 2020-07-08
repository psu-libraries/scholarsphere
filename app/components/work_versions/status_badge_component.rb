# frozen_string_literal: true

class WorkVersions::StatusBadgeComponent < ApplicationComponent
  def initialize(work_version:)
    @work_version = work_version
  end

  private

    attr_reader :work_version

    def html_class
      normalized_state = work_version.aasm_state.parameterize.dasherize
      [
        'badge',
        'version-status',
        "version-status--#{normalized_state}"
      ].join(' ')
    end

    def content
      work_version.aasm_state.downcase
    end
end
