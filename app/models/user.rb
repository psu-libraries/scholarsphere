# frozen_string_literal: true

class User < ApplicationRecord
  devise :omniauthable, omniauth_providers: %i[psu]

  has_many :works,
           foreign_key: 'depositor_id',
           inverse_of: 'depositor',
           dependent: :restrict_with_exception

  has_many :access_controls,
           as: :agent,
           dependent: :destroy

  validates :email,
            presence: true,
            uniqueness: true
end
