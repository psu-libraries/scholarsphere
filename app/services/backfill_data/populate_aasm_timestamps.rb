# frozen_string_literal: true

class BackfillData::PopulateAasmTimestamps
  class << self
    def call
      work_versions.find_each do |wv|
        papertrail_published_at = state_change_timestamp_from_papertrail(wv, 'published')
        papertrail_withdrawn_at = state_change_timestamp_from_papertrail(wv, 'withdrawn')
        papertrail_removed_at = state_change_timestamp_from_papertrail(wv, 'removed')

        external_app_published_at = infer_publication_date_if_external_app(wv)

        wv.published_at = if should_infer_publication_date_from_external_app?(wv)
                            external_app_published_at
                          else
                            papertrail_published_at
                          end
        wv.withdrawn_at = papertrail_withdrawn_at
        wv.removed_at = papertrail_removed_at
        wv.save if wv.changed?
      end
    end

    private

      def work_versions
        WorkVersion
          .includes(
            :versions, # This is the paper trail interface. Confusing name.
            :work
          )
      end

      def state_change_timestamp_from_papertrail(work_version, new_state)
        publication_change = work_version
          .versions
          .find { |version| version.changeset[:aasm_state]&.last.to_s == new_state }

        publication_change&.created_at
      end

      def infer_publication_date_if_external_app(work_version)
        return nil unless should_infer_publication_date_from_external_app?(work_version)

        work_version.work.deposited_at
      end

      # If you wanted to limit this functionality to just SSv3 migrations, then
      # you would do something like:
      #   work_version.external_app_id == {{ssv3 migration's external app id in production}}
      def should_infer_publication_date_from_external_app?(work_version)
        work_version.external_app_id.present?
      end
  end
end
