# frozen_string_literal: true

module Permissions
  extend ActiveSupport::Concern

  included do
    has_many :access_controls,
             as: :resource,
             dependent: :destroy
  end

  include PermissionsBuilder.new(level: AccessControl::Level::DISCOVER, agents: [User, Group])
  include PermissionsBuilder.new(level: AccessControl::Level::READ, agents: [User, Group])
  include PermissionsBuilder.new(level: AccessControl::Level::EDIT, agents: [User, Group])

  def apply_open_access
    return if open_access?

    access_controls.build(access_level: AccessControl::Level::READ, agent: Group.public_agent)
  end

  def open_access?
    access_controls.any? { |control| control.agent.public? }
  end

  def apply_authorized_access
    return if authorized_access?

    access_controls.build(access_level: AccessControl::Level::READ, agent: Group.authorized_agent)
  end

  def authorized_access?
    access_controls.any? { |control| control.agent.authorized? }
  end
end
