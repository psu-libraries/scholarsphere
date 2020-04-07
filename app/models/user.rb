# frozen_string_literal: true

class User < ApplicationRecord
  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User

  devise :omniauthable, omniauth_providers: %i[psu]

  attr_writer :guest

  belongs_to :actor

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

  def works
    actor.deposited_works
      .or(actor.proxy_deposited_works)
      .distinct
  end

  def self.guest
    new(guest: true, groups: [Group.public_agent]).tap(&:readonly!)
  end

  def self.default_groups
    [Group.public_agent, Group.authorized_agent]
  end

  def self.from_omniauth(auth)
    # This service needs a complete overhaul. I'm going to un-factor it for now
    # and then we can refactor once we figure out how the pieces fit together
    # UserRegistrationService.call(auth: auth)

    user = find_or_initialize_by(provider: auth.provider, uid: auth.uid) do |new_user|
      new_user.access_id = auth.info.access_id
      new_user.actor = Actor.find_or_initialize_by(psu_id: new_user.access_id) do |new_actor|
        new_actor.email = auth.info.email
        new_actor.given_name = auth.info.given_name
        new_actor.surname = auth.info.surname
      end
    end

    psu_groups = auth.info.groups
      .map { |ldap_group_name| LdapGroupCleaner.call(ldap_group_name) }
      .compact
      .map { |group_name| Group.find_or_create_by(name: group_name) }

    user.groups = default_groups + psu_groups
    user.email = auth.info.email

    user.save!
    user
  end

  def admin?
    groups.map(&:name).include? Scholarsphere::Application.config.admin_group
  end

  def guest?
    @guest || false
  end

  def name
    actor.default_alias
  end
end
