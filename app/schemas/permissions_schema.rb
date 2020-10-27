# frozen_string_literal: true

class PermissionsSchema < BaseSchema
  delegate :discover_users, :discover_groups,
           :read_users, :read_groups,
           :edit_users, :edit_groups,
           :visibility, to: :resource

  def document
    {
      discover_users_ssim: discover_users.map(&:access_id).uniq,
      discover_groups_ssim: discover_groups.map(&:name).uniq,
      read_users_ssim: read_users.map(&:access_id).uniq,
      read_groups_ssim: read_groups.map(&:name).uniq,
      edit_users_ssim: edit_users.map(&:access_id).uniq,
      edit_groups_ssim: edit_groups.map(&:name).uniq,
      visibility_ssi: visibility
    }
  end
end
