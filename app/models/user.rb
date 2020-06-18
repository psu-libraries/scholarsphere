# frozen_string_literal: true

class User < ApplicationRecord
  class OAuthError < StandardError
    attr_accessor :auth

    def initialize(msg = nil, auth = nil)
      super(msg)
      @auth = auth
    end

    def message
      "#{super}\nAuth: #{auth}"
    end
  end

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

  validates :access_id,
            presence: true,
            uniqueness: { case_sensitive: false }

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
    user = find_or_initialize_by(provider: auth.provider, uid: auth.uid) do |new_user|
      new_user.access_id = auth.info.access_id
      new_user.actor = Actor.find_or_initialize_by(psu_id: new_user.access_id)
    end

    user.email = auth.info.email

    # Update Actor record's values if and only if they are blank
    user.actor.tap do |actor|
      actor.email = actor.email.presence || auth.info.email
      actor.given_name = actor.given_name.presence || auth.info.given_name
      actor.surname = actor.surname.presence || auth.info.surname
    end

    transaction do
      psu_groups = auth.info.groups
        .map { |ldap_group_name| LdapGroupCleaner.call(ldap_group_name) }
        .compact
        .map { |group_name| Group.find_or_create_by(name: group_name) }

      user.groups = default_groups + psu_groups

      user.actor.save!(context: :from_omniauth)
      user.save!(context: :from_omniauth)
    end

    user
  rescue StandardError => e
    raise OAuthError.new(e.message, auth)
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
