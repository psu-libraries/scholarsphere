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

  devise :timeoutable, :omniauthable, omniauth_providers: %i[azure_oauth]

  attr_writer :guest

  belongs_to :actor

  has_many :access_controls,
           as: :agent,
           dependent: :destroy

  has_many :user_group_memberships,
           dependent: :destroy

  has_many :groups,
           through: :user_group_memberships

  has_many :curatorships,
           dependent: :destroy

  has_many :curated_works, through: :curatorships, source: :work

  validates :access_id,
            presence: true,
            uniqueness: { case_sensitive: false }

  def works
    actor.deposited_works
      .or(actor.proxy_deposited_works)
      .distinct
  end

  def collections
    actor.deposited_collections
  end

  def self.guest
    new(guest: true, groups: [Group.public_agent]).tap(&:readonly!)
  end

  def self.default_groups
    [Group.public_agent, Group.authorized_agent]
  end

  def self.from_omniauth(auth)
    user = find_or_initialize_by(provider: auth.provider, uid: auth.uid) do |new_user|
      new_user.access_id = auth.uid
      new_user.actor = Actor.find_or_initialize_by(psu_id: new_user.access_id)
    end

    user.email = auth.info.email

    # Update Actor record's values if and only if they are blank
    user.actor.tap do |actor|
      actor.email = actor.email.presence || auth.info.email
      actor.given_name = actor.given_name.presence || auth.info.given_name
      actor.surname = actor.surname.presence || auth.info.surname || auth.info.family_name
      actor.orcid = actor.orcid.presence || directory_orcid(auth.uid)
    end

    transaction do
      psu_groups = auth.info.groups
        .compact
        .select do |group_name|
          group_name.start_with?('umg') ||
            group_name == Scholarsphere::Application.config.psu_affiliated_group
        end
        .reject { |group_name| group_name.include?(' ') }
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
    admin_available? && admin_enabled
  end

  def admin_available?
    groups.map(&:name).include? Scholarsphere::Application.config.admin_group
  end

  def guest?
    @guest || false
  end

  def psu_affiliated?
    groups.exists?(name: Scholarsphere::Application.config.psu_affiliated_group)
  end

  def name
    actor.display_name
  end

  def self.directory_orcid(uid)
    linked_orcid = PsuIdentity::DirectoryService::Client.new.userid(uid).orc_id
    OrcidId.new(linked_orcid).to_s
  rescue StandardError => e
    logger.error(e)
    nil
  end
end
