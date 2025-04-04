# frozen_string_literal: true

# @abstract Updates the permissions on a resource by replacing all of its access controls. Each control is determined
# using a hash of permissions provided along with the resource. The hash contains the names of users and groups to be
# used for each control and typically would come from a web form or API parameters. The service will either create the
# user or group agents as needed for each access control, or fail if the provided users and groups do not exist.
#
# @example
# {
#   edit_users: ['jxb123'],
#   read_group: ['public'],
#   edit_group: ['umg/up.some.group']
# }
class UpdatePermissionsService
  def self.call(resource:, permissions:, create_agents: false)
    new(resource, permissions, create_agents).update
  end

  attr_reader :resource, :permissions, :create_agents

  def initialize(resource, permissions, create_agents)
    @resource = resource
    @permissions = permissions
    @create_agents = create_agents
  end

  def update
    [:discover_users, :read_users, :edit_users].map do |users|
      resource.send(:"#{users}=", build_user_list(users).compact)
    end
    [:discover_groups, :read_groups, :edit_groups].map do |groups|
      resource.send(:"#{groups}=", build_group_list(groups).compact)
    end
  end

  def create_agents?
    create_agents.is_a?(TrueClass)
  end

  private

    def build_user_list(users)
      permissions.fetch(users, []).map do |user|
        if create_agents?
          UserRegistrationService.call(uid: user)
        else
          User.find_by(uid: user)
        end
      end
    end

    def build_group_list(groups)
      permissions.fetch(groups, []).map do |group|
        if create_agents?
          Group.find_or_initialize_by(name: group)
        else
          Group.find_by(name: group)
        end
      end
    end
end
