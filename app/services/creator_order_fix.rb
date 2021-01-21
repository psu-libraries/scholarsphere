# frozen_string_literal: true

class CreatorOrderFix
  class << self
    def call
      Work.find_each do |work|
        work.versions.order(:version_number).each_with_index do |work_version, index|
          if index.zero?
            update_first_version(work_version)
          else
            update_later_version(work_version, work.versions[index - 1])
          end
        end
      end
    end

    def update_first_version(version)
      return unless all_empty?(version.creator_aliases)

      version.creator_aliases.sort_by(&:id).each_with_index do |creator_alias, index|
        creator_alias.update(position: (index + 1) * 10, changed_by_system: true)
      end
    end

    def update_later_version(current, previous)
      return unless all_empty?(current.creator_aliases)

      previous_ca_lookup = previous.creator_aliases.map { |ca| [ca.actor_id, ca.position] }.to_h
      current.creator_aliases.each do |creator_alias|
        creator_alias.update(position: previous_ca_lookup[creator_alias.actor_id], changed_by_system: true)
      end
    end

    def all_empty?(aliases)
      positions = aliases.map(&:position)

      if positions.uniq.count > 1 && positions.uniq.any?(nil)
        raise StandardError, "Work #{aliases.first.work_version.work.uuid} can't be corrected"
      else
        positions.uniq == [nil]
      end
    end
  end
end
