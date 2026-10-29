# frozen_string_literal: true

# It is not uncommon for there to be two Actor records for the same individual,
# one identified by PSU ID and another by ORCiD. This service reconciles them
# to prevent a uniqueness conflict on ORCiD.
class ActorReconciliationService
  def self.call(user:, save_context: nil)
    new(user:, save_context:).call
  end

  def initialize(user:, save_context:)
    @user = user
    @save_context = save_context
  end

  def call
    orcid = User.directory_orcid(user.access_id)
    return user if orcid.blank?

    orcid_actor = Actor.find_by(orcid: orcid)
    return user if orcid_actor.nil?

    psu_id_actor = user.actor

    reconcile(psu_id_actor, orcid_actor)
    user
  end

  private

    attr_reader :user, :save_context

    def reconcile(psu_id_actor, orcid_actor)
      ActiveRecord::Base.transaction do
        orcid_actor.deposited_works.each { |work| work.update!(depositor_id: psu_id_actor.id) }
        orcid_actor.proxy_deposited_works.each { |work| work.update!(proxy_id: psu_id_actor.id) }
        psu_id_actor.authorships << orcid_actor.authorships
        psu_id_actor.created_work_versions << orcid_actor.created_work_versions
        psu_id_actor.created_collections << orcid_actor.created_collections
        orcid_actor.deposited_collections.each { |collection| collection.update!(depositor_id: psu_id_actor.id) }
        orcid_transfer = orcid_actor.orcid
        orcid_actor.delete
        # Assigning the ORCiD must be done after deleting the ORCiD-only actor to avoid uniqueness constraint violations.
        psu_id_actor.orcid = orcid_transfer
        psu_id_actor.save!(context: save_context)
      end
    end
end
