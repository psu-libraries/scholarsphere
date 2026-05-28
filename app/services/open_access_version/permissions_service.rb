# frozen_string_literal: true

module OpenAccessVersion
  class PermissionsService < PermissionsClient
    def initialize(doi)
      super()

      @doi = doi.to_s.sub(%r{^https?://doi\.org/}, '')
    end

    def publisher_statement(version)
      this_version(version)['deposit_statement'].presence
    end

    def embargo_end_date(version)
      if this_version(version)['embargo_end'].present?
        Date.parse(this_version(version)['embargo_end'], '%Y-%m-%d')
      end
    end

    def licence(version)
      map_licence(this_version(version)['licence'].presence)
    end

    def versions_found?
      versions = []
      versions << VersionValues::ACCEPTED if accepted_version.present?
      versions << VersionValues::PUBLISHED if published_version.present?
      versions
    end

    def current_version_found?(version)
      this_version(version).present?
    end

    def permissions_found?
      all_permissions.present?
    end

    private

      def this_version(version)
        return accepted_version if accepted_version['version'] == version

        return published_version if published_version['version'] == version

        {}
      end
  end
end
