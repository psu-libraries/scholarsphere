# frozen_string_literal: true

module AuthorshipMigration
  class RemoveBadActors
    def self.call
      bad_actors = Actor.where(psu_id: nil, orcid: nil)

      Authorship.where(actor_id: bad_actors).find_each do |authorship|
        authorship.update(
          actor_id: nil,
          changed_by_system: true
        )
      end

      bad_actors.delete_all
    end
  end
end
