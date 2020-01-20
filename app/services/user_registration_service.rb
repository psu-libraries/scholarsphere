# frozen_string_literal: true

# @abstract Correctly registers new and existing users whether they are coming from the user interface via our auth
# proxy service, or their works are being migrated via the ingest API. Calls from the API will only include a uid and
# will register a new user if non exists. API calls will NOT update existing users (see notes below). Call from the UI,
# which provide a OmniAuth hash from our auth proxy, will update the user record.

class UserRegistrationService
  # @param [OmniAuth::AuthHash] from our authproxy service
  # @param [String] uid or access_id of the user, such as jxd123
  def self.call(auth: OmniAuth::AuthHash.new, uid: nil)
    if uid.nil?
      new(auth).register
    else
      new(uid).register(api: true)
    end
  end

  attr_reader :auth

  def initialize(arg)
    @auth = if arg.is_a?(OmniAuth::AuthHash)
              arg
            else
              build_authorization_hash(arg)
            end
  end

  def register(api: false)
    raise ArgumentError, 'cannot register a user without a uid' if auth.uid.nil?

    if api
      register_for_api
    else
      update_user
    end

    user
  end

  private

    def build_authorization_hash(access_id)
      OmniAuth::AuthHash.new.tap do |auth_hash|
        auth_hash.uid = access_id
        auth_hash.provider = 'psu'
        auth_hash.info = build_info_hash(access_id)
      end
    end

    def build_info_hash(access_id)
      OmniAuth::AuthHash::InfoHash.new(access_id: access_id, groups: [], email: "#{access_id}@psu.edu")
    end

    # @note In order to satisfy migration needs, API calls will create the user if needed, but otherwise it should
    # not update existing users unless we integrate it with our auth proxy service.
    def register_for_api
      return user if user.persisted?

      user.update(email: auth.info.email, groups: User.default_groups)
    end

    def user
      @user ||= User.find_or_initialize_by(provider: auth.provider, uid: auth.uid) do |new_user|
        new_user.access_id = auth.info.access_id
      end
    end

    def update_user
      user.update(
        email: auth.info.email,
        given_name: auth.info.given_name,
        surname: auth.info.surname,
        groups: psu_groups + User.default_groups
      )
    end

    def psu_groups
      auth.info.groups
        .map { |ldap_group_name| LdapGroupCleaner.call(ldap_group_name) }
        .compact
        .map do |group_name|
        Group.find_or_create_by(name: group_name)
      end
    end
end
