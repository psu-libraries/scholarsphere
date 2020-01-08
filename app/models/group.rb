# frozen_string_literal: true

class Group < ApplicationRecord
  PUBLIC_AGENT_NAME = 'public'
  AUTHORIZED_AGENT_NAME = 'authorized'

  # @note Database cleaner and transactional fixtures are causing caching problems so we re-find/create each time but
  # only in test.
  def self.public_agent
    if Rails.env.test?
      find_or_create_by(name: PUBLIC_AGENT_NAME)
    else
      @public_agent ||= find_or_create_by(name: PUBLIC_AGENT_NAME)
    end
  end
  delegate :public_agent, to: :class

  # @note Database cleaner and transactional fixtures are causing caching problems so we re-find/create each time but
  # only in test.
  def self.authorized_agent
    if Rails.env.test?
      find_or_create_by(name: AUTHORIZED_AGENT_NAME)
    else
      @authorized_agent ||= find_or_create_by(name: AUTHORIZED_AGENT_NAME)
    end
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
