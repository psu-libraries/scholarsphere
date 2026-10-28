# frozen_string_literal: true

# It is not uncommon for there to be two Actor records for the same individual,
# one identified by PSU ID and another by ORCiD. This service reconciles them.
class ActorReconciliationService
  def self.call(user:)
    new(user:).call
  end

  def initialize(user:)
    @user = user
  end

  def call
    # A uniqueness constraint on ORCiD ensures that if the PSU ID actor already has an ORCiD,
    # it is not possible to have a duplicate ORCiD in the system.
    psu_id_actor = user.actor
    return user if psu_id_actor.orcid.present?

    orcid = User.directory_orcid(user.access_id)
    return user if orcid.blank?

    orcid_actor = Actor.find_by(orcid: orcid)
    return user if orcid_actor.nil?

    reconcile(psu_id_actor, orcid_actor)
    user
  end

  private

    attr_reader :user

    def reconcile(psu_id_actor, orcid_actor)
      ActiveRecord::Base.transaction do
        orcid_actor.deposited_works.each { |work| work.update!(depositor_id: psu_id_actor.id) }
        orcid_actor.proxy_deposited_works.each { |work| work.update!(proxy_id: psu_id_actor.id) }
        psu_id_actor.authorships << orcid_actor.authorships
        psu_id_actor.created_work_versions << orcid_actor.created_work_versions
        psu_id_actor.created_collections << orcid_actor.created_collections
        orcid_actor.deposited_collections.each { |collection| collection.update!(depositor_id: psu_id_actor.id) }
        psu_id_actor.save!
        orcid_actor.delete
        # Assigning the ORCiD must be done after deleting the ORCiD-only actor to avoid uniqueness constraint violations.
        psu_id_actor.orcid = orcid_actor.orcid
        psu_id_actor.save!
      end
    end
end
