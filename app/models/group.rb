# frozen_string_literal: true

class Group < ApplicationRecord
  PUBLIC_AGENT_NAME = 'public'
  AUTHORIZED_AGENT_NAME = 'authorized'
  PSU_AFFILIATED_AGENT_NAME = Scholarsphere::Application.config.psu_affiliated_group

  # @note This agent must be seeded in the database prior to deployment
  def self.public_agent
    @public_agent ||= find_by!(name: PUBLIC_AGENT_NAME)
  end
  delegate :public_agent, to: :class

  # @note This agent must be seeded in the database prior to deployment
  def self.authorized_agent
    @authorized_agent ||= find_by!(name: AUTHORIZED_AGENT_NAME)
  end
  delegate :authorized_agent, to: :class

  # @note This agent must be seeded in the database unless connection to azure is live
  # The group will be imported during the first login of a PSU affiliated user
  def self.psu_affiliated_agent
    @psu_affiliated_agent ||= find_by!(name: PSU_AFFILIATED_AGENT_NAME)
  end
  delegate :psu_affiliated_agent, to: :class

  def public?
    self == public_agent
  end

  def authorized?
    self == authorized_agent
  end

  has_many :access_controls,
           as: :agent,
           dependent: :destroy

  has_many :user_group_memberships,
           dependent: :destroy

  has_many :users,
           through: :user_group_memberships

  validates :name,
            presence: true,
            uniqueness: { case_sensitive: false }
end
