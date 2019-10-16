# frozen_string_literal: true

class Creator < ApplicationRecord
  has_many :aliases,
           dependent: :restrict_with_exception

  # TODO validations? Indexes?
end
