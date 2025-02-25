# frozen_string_literal: true

# @abstract Returns a hash with the differences between the file memberships of two WorkVersions. Renamed files
# is array of tuples, each with a FileVersionMembership, representating the two changed memberships. Added and deleted
# files are returned as arrays of FileVersionMembership objects.
# @example Given two objects with two different titles
#   >  FileVersionMembershipDiff.call(obj1, obj2)
#   => {
#        renamed:
#          [
#            [FileVersionMembership, FileVersionMembership],
#            [FileVersionMembership, FileVersionMembership]
#          ]
#        added: [FileVersionMembership, FileVersionMembership],
#        deleted: [FileVersionMembership]
#      }
#
class FileVersionMembershipDiff
  # @param obj1 [WorkVersion]
  # @param obj2 [WorkVersion]
  def self.call(*)
    new(*).diff
  end

  attr_reader :base_version, :comparison_version

  def initialize(*args)
    @base_version = args[0]
    @comparison_version = args[1]
  end

  def diff
    { renamed: renamed, deleted: deleted, added: added }
  end

  # @return [Array<[FileVersionMembership, FileVersionMembership]>]
  def renamed
    identical_file_resource_ids.map do |id|
      original_file = base_version_memberships.find { |mem| mem.file_resource_id == id }
      renamed_file = comparison_version_memberships.find { |mem| mem.file_resource_id == id }
      next if original_file.title == renamed_file.title

      [original_file, renamed_file]
    end.compact
  end

  # @return [Array<FileVersionMembership>]
  def deleted
    base_version_memberships.reject do |file_version_membership|
      identical_file_resource_ids.include?(file_version_membership.file_resource_id)
    end
  end

  # @return [Array<FileVersionMembership>]
  def added
    comparison_version_memberships.reject do |file_version_membership|
      identical_file_resource_ids.include?(file_version_membership.file_resource_id)
    end
  end

  private

    def base_version_memberships
      @base_version_memberships ||= base_version.file_version_memberships
    end

    def comparison_version_memberships
      @comparison_version_memberships ||= comparison_version.file_version_memberships
    end

    def identical_file_resource_ids
      @identical_file_resource_ids ||= begin
        base = Set.new(base_version_memberships.map(&:file_resource_id))
        comparison = Set.new(comparison_version_memberships.map(&:file_resource_id))

        base.intersection(comparison)
      end
    end
end
