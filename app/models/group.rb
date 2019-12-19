# frozen_string_literal: true

class Group < ApplicationRecord
  PUBLIC_AGENT_NAME = 'public'
  AUTHORIZED_AGENT_NAME = 'authorized'

  def self.public_agent
    @public_agent ||= find_or_create_by(name: PUBLIC_AGENT_NAME)
  end
  delegate :public_agent, to: :class

  def self.authorized_agent
    @authorized_agent ||= find_or_create_by(name: AUTHORIZED_AGENT_NAME)
  end
  delegate :authorized_agent, to: :class

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
end
