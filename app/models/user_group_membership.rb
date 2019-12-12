# frozen_string_literal: true

class UserGroupMembership < ApplicationRecord
  belongs_to :user
  belongs_to :group
end
