# frozen_string_literal: true

class OawPermissionsService < OawPermissionsClient
  def initialize(doi, version)
    raise InvalidVersion if VALID_VERSIONS.exclude?(version)

    super()
    @doi = doi
    @version = version
  end

  def set_statement
    this_version['deposit_statement'].presence
  end

  def embargo_end_date
    if this_version['embargo_end'].present?
      Date.parse(this_version['embargo_end'], '%Y-%m-%d')
    end
  end

  def licence
    map_licence(this_version['licence'].presence)
  end

  def other_version_preferred?
    return false if this_version.present?

    return true if accepted_version.present? || published_version.present?

    false
  end

  def this_version
    return accepted_version if accepted_version['version'] == version

    return published_version if published_version['version'] == version

    {}
  end

  def permissions_found?
    all_permissions.present?
  end
end