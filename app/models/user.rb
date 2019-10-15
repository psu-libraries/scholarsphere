# frozen_string_literal: true

class User < ApplicationRecord
  has_many :works,
           foreign_key: 'depositor_id',
           inverse_of: 'depositor',
           dependent: :restrict_with_exception

  validates :email,
            presence: true,
            uniqueness: true
end
