# frozen_string_literal: true

# @abstract This is similar to the StatusBadgeComponent, but includes the
# version number as part of the badge. Used on the search results and dashboard.
class WorkVersions::VersionStatusBadgeComponent < ApplicationComponent
  def initialize(work_version:)
    @work_version = work_version
  end

  def render?
    content.present?
  end

  private

    attr_reader :work_version

    def html_class
      [
        'badge',
        'badge--text',
        *state_classes
      ].join(' ')
    end

    def content
      work_version.aasm_state
    end

    # TODO we need to extract this logic out into a decorator. It's already
    # duplicated in Dashboard::WorkVersionDecorator but once we're done with the
    # redesign I think it would be smart to factor them all into the same place.
    #
    # Likewise, version_name is not currently indexed in Solr, hence why we need
    # to do the test below. Once we sort out the decorator as mentioned above,
    # then we should index that in solr and eliminate all this logic below.
    def version
      version_name = work_version.respond_to?(:version_name) && work_version.version_name
      "V#{version_name.presence || work_version.version_number}"
    end

    def state_classes
      {
        WorkVersion::STATE_DRAFT => %w(badge--dark-blue badge--outline),
        WorkVersion::STATE_PUBLISHED => %w(badge--dark-blue),
        WorkVersion::STATE_WITHDRAWN => %w(badge--dark-red)
      }.with_indifferent_access.fetch(work_version.aasm_state)
    end
end
