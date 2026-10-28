# frozen_string_literal: true

class ActorIdentityResolver
  def self.call(psu_id:)
    linked_orcid = PsuIdentity::DirectoryService::Client.new.userid(psu_id).orc_id
    OrcidId.new(linked_orcid).to_s if linked_orcid.present?
  rescue StandardError => e
    Rails.logger.error("Unable to resolve Actor ORCID from PSU ID: #{e.message}")
    nil
  end
end
