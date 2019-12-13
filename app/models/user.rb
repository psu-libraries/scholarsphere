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

  has_many :user_group_memberships,
           dependent: :destroy

  has_many :groups,
           through: :user_group_memberships

  validates :email,
            presence: true,
            uniqueness: true

  def self.from_omniauth(auth)
    user = User.find_or_initialize_by(provider: auth.provider, uid: auth.uid) do |new_user|
      # Written once, when the user is created, then never again
      new_user.access_id = auth.info.access_id
    end

    # Updated every login
    user.email = auth.info.email
    user.given_name = auth.info.given_name
    user.surname = auth.info.surname

    user.groups = auth.info.groups.map do |group_name|
      Group.find_or_create_by(name: group_name)
    end

    user.save!

    user
  end

  def admin?
    groups.map(&:name).include? Scholarsphere::Application.config.admin_group
  end

  def name
    "#{given_name} #{surname}"
  end
end
