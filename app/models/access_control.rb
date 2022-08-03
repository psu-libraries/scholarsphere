# frozen_string_literal: true

class AccessControl < ApplicationRecord
  class Level
    DISCOVER = 'discover'
    READ = 'read'
    EDIT = 'edit'

    def self.all
      [DISCOVER, READ, EDIT]
    end

    def self.default
      DISCOVER
    end
  end

  belongs_to :agent,
             polymorphic: true
  belongs_to :resource,
             polymorphic: true

  validates :access_level,
            uniqueness: { scope: [:agent, :resource] },
            inclusion: { in: AccessControl::Level.all }
  def public?
    agent.is_a?(Group) && agent.public? && access_level == AccessControl::Level::READ
  end

  def authorized?
    agent.is_a?(Group) && agent.authorized? && access_level == AccessControl::Level::READ
  end
end
