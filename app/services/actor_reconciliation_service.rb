# frozen_string_literal: true

class ActorReconciliationService
  def self.call(user:)
    new(user:).call
  end

  def initialize(user:)
    @user = user
  end

  def call
    orcid = User.directory_orcid(user.access_id)
    return user if orcid.blank?

    psu_actor = user.actor
    orcid_actor = Actor.find_by(orcid: orcid)
    return user if orcid_actor.nil? || (psu_actor == orcid_actor)

    reconcile(psu_actor, orcid_actor)
    user
  end

  private

    attr_reader :user

    def reconcile(psu_actor, orcid_actor)
      ActiveRecord::Base.transaction do
        orcid_actor.deposited_works.each { |work| work.update!(depositor_id: psu_actor.id) }
        orcid_actor.proxy_deposited_works.each { |work| work.update!(proxy_id: psu_actor.id) }
        psu_actor.authorships << orcid_actor.authorships
        psu_actor.created_work_versions << orcid_actor.created_work_versions
        psu_actor.created_collections << orcid_actor.created_collections
        orcid_actor.deposited_collections.each { |collection| collection.update!(depositor_id: psu_actor.id) }
        psu_actor.save!
        orcid_actor.delete
        psu_actor.orcid = orcid_actor.orcid
        psu_actor.save!
      end
    end
end
