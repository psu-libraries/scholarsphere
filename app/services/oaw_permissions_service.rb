# frozen_string_literal: true

class OawPermissionsService < OawPermissionsClient
  def initialize(doi)
    # raise InvalidVersion if VALID_VERSIONS.exclude?(version)

    super()
    @doi = doi
    # @version = version
  end

  def set_statement(version)
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

  def other_version_preferred?(version)
    return false if this_version(version).present?

    return true if accepted_version.present? || published_version.present?

    false
  end

  def versions_found?
    versions = []
    versions << 'acceptedVersion' if accepted_version.present?
    versions << 'publishedVersion' if published_version.present?
    versions
  end

  def current_version_found?(version)
    this_version(version).present?
  end

  def this_version(version)
    return accepted_version if accepted_version['version'] == version

    return published_version if published_version['version'] == version

    {}
  end

  def permissions_found?
    all_permissions.present?
  end
end