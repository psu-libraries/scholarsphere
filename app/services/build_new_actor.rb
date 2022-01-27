# frozen_string_literal: true

class BuildNewActor
  class << self
    def call(psu_id: nil, orcid: nil)
      raise ArgumentError, 'You must provide either an Orcid or a Penn State access id' if psu_id.nil? && orcid.nil?

      psu_actor = build_with_psu_id(psu_id, orcid)
      orcid_actor = build_with_orcid(orcid)

      psu_actor || orcid_actor
    end

    def build_with_psu_id(psu_id, orcid)
      return if psu_id.nil?

      user = PsuIdentity::SearchService::Client.new.userid(psu_id)

      Actor.find_or_initialize_by(psu_id: user.user_id) do |actor|
        actor.given_name = user.preferred_given_name
        actor.surname = user.preferred_family_name
        actor.display_name = user.display_name
        actor.email = user.university_email
        actor.orcid = orcid
      end
    end

    def build_with_orcid(orcid)
      return if orcid.nil?

      id = OrcidId.new(orcid)
      person = Orcid::Public::Person.new(id.to_human)

      Actor.find_or_initialize_by(orcid: id.to_s) do |actor|
        actor.given_name = person.given_names
        actor.surname =  person.family_name
        actor.display_name = person.credit_name
        actor.email = person.emails.default
      end
    end
  end
end
