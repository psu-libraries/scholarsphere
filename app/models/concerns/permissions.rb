# frozen_string_literal: true

module Permissions
  extend ActiveSupport::Concern

  class Visibility
    OPEN = 'open'
    AUTHORIZED = 'authenticated'
    PRIVATE = 'restricted'

    def self.all
      [OPEN, AUTHORIZED, PRIVATE]
    end

    def self.default
      OPEN
    end

    def self.display(visibility)
      I18n.t("activerecord.attributes.permissions.visibility.#{visibility}")
    end

    def self.options_for_select_box
      [OPEN, AUTHORIZED]
        .map { |vis| [display(vis), vis] }
    end
  end

  included do
    has_many :access_controls,
             as: :resource,
             dependent: :destroy,
             autosave: true
  end

  # @note This is to exclude agents from the []= assigning process, and avoids the problem of removing visibility
  # agents when setting permissions on a resource.
  class GroupsToIgnore
    def self.call
      [Group.public_agent, Group.authorized_agent, Group.psu_affiliated_agent]
    end
  end

  include PermissionsBuilder.new(
    level: AccessControl::Level::DISCOVER,
    agents: [User, Group],
    white_list: GroupsToIgnore
  )

  include PermissionsBuilder.new(
    level: AccessControl::Level::READ,
    agents: [User, Group],
    inherit: AccessControl::Level::DISCOVER,
    white_list: GroupsToIgnore
  )

  include PermissionsBuilder.new(
    level: AccessControl::Level::EDIT,
    agents: [User, Group],
    inherit: [AccessControl::Level::DISCOVER, AccessControl::Level::READ],
    white_list: GroupsToIgnore
  )

  def grant_open_access
    return if open_access?

    revoke_authorized_access
    grant_read_access(Group.public_agent)
  end

  def revoke_open_access
    revoke_read_access(Group.public_agent)
  end

  def open_access?
    discover_access?(Group.public_agent) && read_access?(Group.public_agent)
  end

  def grant_authorized_access
    return if authorized_access?

    revoke_open_access
    grant_read_access(Group.authorized_agent)
    grant_discover_access(Group.public_agent)
  end

  def revoke_authorized_access
    revoke_read_access(Group.authorized_agent)
    revoke_discover_access(Group.public_agent)
  end

  def authorized_access?
    discover_access?(Group.authorized_agent) &&
      read_access?(Group.authorized_agent) &&
      discover_access?(Group.public_agent)
  end

  # @note This value is determined based the presence of a set of predetermined access controls. If there are no access
  # controls, or none that conform to either open or authorized levels, a private visibility is assumed.
  def visibility
    if open_access?
      Visibility::OPEN
    elsif authorized_access?
      Visibility::AUTHORIZED
    else
      Visibility::PRIVATE
    end
  end

  # @note This is a misleading use of a setting method, because there is no 'visibility' attribute that is set in the
  # database. Instead, the value passed to the setter triggers a method that adds or removes a set of predetermined
  # ACLs. The value must be one of Permissions::Visibility. If it is not, then no changes will be made the object's
  # access controls and nil is returned.
  def visibility=(level)
    case level
    when Visibility::OPEN
      grant_open_access
    when Visibility::AUTHORIZED
      grant_authorized_access
    when Visibility::PRIVATE
      revoke_open_access && revoke_authorized_access
    end
  end

  def visibility_agent
    return Group.public_agent if open_access?
    return Group.authorized_agent if authorized_access?
  end
end
