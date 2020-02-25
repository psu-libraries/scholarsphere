# frozen_string_literal: true

class PermissionsSchema < BaseSchema
  delegate :discover_users, :discover_groups, :read_users, :read_groups, :visibility, to: :resource

  def document
    {
      discover_users_ssim: (discover_users + read_users).map(&:access_id).uniq,
      discover_groups_ssim: (discover_groups + read_groups).map(&:name).uniq,
      visibility_ssi: visibility
    }
  end
end
