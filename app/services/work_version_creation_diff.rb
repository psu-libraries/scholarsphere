# frozen_string_literal: true

# @abstract Returns a hash with the differences between the file memberships of two WorkVersions. Renamed files
# is array of tuples, each with a WorkVersionCreation, representating the two changed memberships. Added and deleted
# files are returned as arrays of WorkVersionCreation objects.
# @example Given two objects with two different aliass
#   >  FileVersionMembershipDiff.call(obj1, obj2)
#   => {
#        renamed:
#          [
#            [WorkVersionCreation, WorkVersionCreation],
#            [WorkVersionCreation, WorkVersionCreation]
#          ]
#        added: [WorkVersionCreation, WorkVersionCreation],
#        deleted: [WorkVersionCreation]
#      }
#
class WorkVersionCreationDiff
  # @param obj1 [WorkVersion]
  # @param obj2 [WorkVersion]
  def self.call(*args)
    new(*args).diff
  end

  attr_reader :base_version, :comparison_version

  def initialize(*args)
    @base_version = args[0]
    @comparison_version = args[1]
  end

  def diff
    { renamed: renamed, deleted: deleted, added: added }
  end

  # @return [Array<[WorkVersionCreation, WorkVersionCreation]>]
  def renamed
    identical_work_version_membership_ids.map do |id|
      original_creator_alias = base_version_creator_aliases.find { |creator_alias| creator_alias.actor_id == id }
      renamed_creator_alias = comparison_version_creator_aliases.find { |creator_alias| creator_alias.actor_id == id }
      next if original_creator_alias.alias == renamed_creator_alias.alias

      [original_creator_alias, renamed_creator_alias]
    end.compact
  end

  # @return [Array<WorkVersionCreation>]
  def deleted
    base_version_creator_aliases.reject do |work_version_creation|
      identical_work_version_membership_ids.include?(work_version_creation.actor_id)
    end
  end

  # @return [Array<WorkVersionCreation>]
  def added
    comparison_version_creator_aliases.reject do |work_version_creation|
      identical_work_version_membership_ids.include?(work_version_creation.actor_id)
    end
  end

  private

    def base_version_creator_aliases
      @base_version_creator_aliases ||= base_version.creator_aliases
    end

    def comparison_version_creator_aliases
      @comparison_version_creator_aliases ||= comparison_version.creator_aliases
    end

    def identical_work_version_membership_ids
      @identical_work_version_membership_ids ||= begin
        base = Set.new(base_version_creator_aliases.map(&:actor_id))
        comparison = Set.new(comparison_version_creator_aliases.map(&:actor_id))

        base.intersection(comparison)
      end
    end
end
