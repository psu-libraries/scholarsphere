# frozen_string_literal: true

class User < ApplicationRecord
  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User

  devise :omniauthable, omniauth_providers: %i[psu]

  attr_writer :guest

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

  def self.guest
    new(guest: true, groups: [Group.public_agent]).tap(&:readonly!)
  end

  def self.default_groups
    [Group.public_agent, Group.authorized_agent]
  end

  def self.from_omniauth(auth)
    UserRegistrationService.call(auth: auth)
  end

  def admin?
    groups.map(&:name).include? Scholarsphere::Application.config.admin_group
  end

  def name
    "#{given_name} #{surname}"
  end

  def guest?
    @guest || false
  end
end
