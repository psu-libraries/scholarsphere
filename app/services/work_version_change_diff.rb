# frozen_string_literal: true

# @abstract Returns a hash with the differences in the `metadata` jsonb column
# in a PaperTrail::Version of a WorkVersion object.
#
# When I update the `metadata` of a WorkVersion, PaperTrail will store that
# change in a PaperTrail::Version object. Passing that PaperTrail::Version to
# this class will return the differences in metadata of that change.
#
# PaperTrail _does_ have the ability to perform its own diffs of changes, and
# therefore one might think that this class should be unecessary. Unfortunately
# that feature of Papertrail is thwarted by our use of a jsonb column to store
# the metadata.
#
# @example Given a PaperTrail::Version of a WorkVersion where title was updated:
#   >  MetadataDiff(paper_trail_version)
#   => { title: ["Original title", "Updated title"] }
class WorkVersionChangeDiff
  def self.call(paper_trail_version, options = {})
    return {} unless paper_trail_version.object_changes.key?('metadata')

    old_metadata = paper_trail_version.object_changes['metadata'][0]
    new_metadata = paper_trail_version.object_changes['metadata'][1]

    MetadataDiff.call(
      OpenStruct.new(metadata: old_metadata),
      OpenStruct.new(metadata: new_metadata),
      options
    )
  end
end
