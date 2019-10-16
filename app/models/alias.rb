# frozen_string_literal: true

class Alias < ApplicationRecord
  belongs_to :creator
  has_many :work_creations,
           dependent: :restrict_with_exception
  has_many :works,
           through: :work_creations
end
