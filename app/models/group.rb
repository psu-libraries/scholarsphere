# frozen_string_literal: true

class Group < ApplicationRecord
  has_many :access_controls,
           as: :agent,
           dependent: :destroy

  has_many :user_group_memberships,
           dependent: :destroy

  has_many :users,
           through: :user_group_memberships
end
