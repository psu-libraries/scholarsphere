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
# >  pole.apply_scratch_access(dog)
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
  def initialize(level:, agents:)
    define_method "#{level}_agents" do
      access_controls.map do |control|
        control.agent if control.access_level == level
      end
    end

    define_method "#{level}_access?" do |agent|
      send("#{level}_agents").include?(agent)
    end

    define_method "apply_#{level}_access" do |agent|
      return if send("#{level}_access?", agent)

      access_controls.build(access_level: level, agent: agent)
    end

    agents.each do |agent|
      define_method "#{level}_#{agent.to_s.pluralize.downcase}" do
        send("#{level}_agents").select { |level_agent| level_agent.is_a?(agent) }
      end
    end
  end
end
