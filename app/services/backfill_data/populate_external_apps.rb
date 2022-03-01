# frozen_string_literal: true

# When SSv3 works were migrated across to v4 (this app), the only record of
# where those works came from was in PaperTrail. The same is true for any
# WorkVersion created by the API. We decided to make this linkage explicit with
# a foreign key on WorkVersion, and this class backports all our old Versions
# by crawling through the PaperTrail versions and trying to sleuth out this
# information.
#
# This class will be run once to migrate the old data over, then can (and
# should) be deleted
class BackfillData::PopulateExternalApps
  class << self
    def call
      work_versions.each do |wv|
        first_external_app_global_id = wv
          .versions
          .map(&:whodunnit)
          .map { |gid| GlobalID.parse(gid) }
          .filter { |global_id| global_id&.model_class == ExternalApp }
          .first

        wv.update(external_app_id: first_external_app_global_id.model_id) if first_external_app_global_id.present?
      end
    end

    def work_versions
      WorkVersion
        .includes(:versions) # This unfortunately-named association is the paper trail interface
    end
  end
end
