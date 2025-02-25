# frozen_string_literal: true

# @abstract Uses the module builder pattern to add permissions to a class based on an agent type and a level of access.
#
# @example
# class ControledResource
#   include PermissionsBuilder.new(level: 'scratch', agents: [Dog, Cat])
# end
#
# >  pole = ControlledResource.new
# >  dog = Dog.new
# >  cat = Cat.new
# >  pole.grant_scratch_access(dog)
# >  pole.scratch_access?(dog)
# => true
# >  pole.scratch_access?(cat)
# => false
# >  pole.scratch_agents
# => [dog]
# >  pole.scratch_dogs
# => [dog]
# >  pole.scratch_cats
# => []
#

class PermissionsBuilder < Module
  def initialize(level:, agents:, inherit: [], white_list: nil)
    define_method :"#{level}_agents" do
      access_controls.map do |control|
        control.agent if control.access_level == level
      end
    end

    # @note There's a little bit of "concern bleed" because an agent, like a user, can have associated agents, i.e.
    # groups, which impact how we determine access. For now, we can ask the agent if it has any groups, and that should
    # be fine, but we can refactor later, if desired.
    define_method :"#{level}_access?" do |agent|
      associated_agents = agent.try(:groups) || []
      available_agents = associated_agents.to_a + [agent]
      send(:"#{level}_agents").intersect?(available_agents)
    end

    define_method :"grant_#{level}_access" do |*args|
      args.map do |agent|
        Array.wrap(inherit).push(level).map do |access_level|
          access_controls.build(access_level: access_level, agent: agent) unless send(:"#{level}_access?", agent)
        end
      end
    end

    define_method :"revoke_#{level}_access" do |*args|
      args.map do |agent|
        Array.wrap(inherit).push(level).map do |access_level|
          self.access_controls = access_controls.reject do |control|
            control.access_level == access_level && control.agent == agent
          end
        end
      end
    end

    agents.each do |agent|
      define_method :"#{level}_#{agent.to_s.pluralize.downcase}" do
        send(:"#{level}_agents").select { |level_agent| level_agent.is_a?(agent) }
      end
    end

    agents.each do |agent|
      define_method :"#{level}_#{agent.to_s.pluralize.downcase}=" do |list|
        # Remove access to agents not in the list or in the white list function
        revoke = send(:"#{level}_#{agent.to_s.pluralize.downcase}") - list - Array.wrap(white_list.try(:call))
        send(:"revoke_#{level}_access", *revoke)

        # Grant access to agents in the list
        send(:"grant_#{level}_access", *list)
      end
    end
  end
end
