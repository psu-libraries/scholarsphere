# frozen_string_literal: true

class WorkVersions::StatusBadgeComponent < ApplicationComponent
  STATE_CLASSES = {
    WorkVersion::STATE_DRAFT => %w(badge--dark-blue badge--outline),
    WorkVersion::STATE_PUBLISHED => %w(badge--dark-blue),
    WorkVersion::STATE_WITHDRAWN => %w(badge--dark-red)
  }.with_indifferent_access.freeze

  INVERTED_STATE_CLASSES = {
    WorkVersion::STATE_DRAFT => %w(badge-light badge--outline),
    WorkVersion::STATE_PUBLISHED => %w(badge-light),
    WorkVersion::STATE_WITHDRAWN => %w(badge--light-red)
  }.with_indifferent_access.freeze

  def initialize(work_version:, invert: false)
    @work_version = work_version
    @invert = invert
  end

  private

    attr_reader :work_version,
                :invert

    def html_class
      [
        'badge',
        'badge--nudge-up',
        'ml-1',
        *state_classes
      ].join(' ')
    end

    def content
      work_version.aasm_state
    end

    def state_classes
      class_hash = invert ? INVERTED_STATE_CLASSES : STATE_CLASSES
      class_hash[work_version.aasm_state]
    end
end
