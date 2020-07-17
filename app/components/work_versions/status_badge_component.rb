# frozen_string_literal: true

class WorkVersions::StatusBadgeComponent < ApplicationComponent
  def initialize(work_version:)
    @work_version = work_version
  end

  private

    attr_reader :work_version

    def html_class
      [
        'badge',
        'badge--text',
        "badge--#{color.fetch(content, 'red')}"
      ].join(' ')
    end

    def content
      work_version.aasm_state
    end

    def version
      "V#{work_version.version_number}"
    end

    def color
      HashWithIndifferentAccess.new({
                                      WorkVersion::STATE_DRAFT => 'gray-800',
                                      WorkVersion::STATE_PUBLISHED => 'dark-blue'
                                    })
    end
end
