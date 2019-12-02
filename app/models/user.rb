# frozen_string_literal: true

class User < ApplicationRecord
  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User

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

  # TODO Which fields do we want updated each time a user logs in?
  #   - Group memberships
  def self.from_omniauth(auth)
    User.find_or_create_by(provider: auth.provider, uid: auth.uid) do |new_user|
      new_user.access_id = auth.info.access_id
      new_user.email = auth.info.email
      new_user.given_name = auth.info.given_name
      new_user.surname = auth.info.surname
    end
  end

  def name
    "#{given_name} #{surname}"
  end
end
