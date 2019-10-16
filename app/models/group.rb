# frozen_string_literal: true

class Group < ApplicationRecord
  has_many :access_controls,
           as: :agent,
           dependent: :destroy
end
