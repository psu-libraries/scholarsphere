# frozen_string_literal: true

class AllWorkVersionsReport
  def name
    'all_work_versions'
  end

  def headers
    %w[
      id
      work_id
      state
      version_number
      title
      subtitle
      version_name
      keyword
      rights
      description
      publisher_statement
      resource_type
      contributor
      publisher
      published_date
      subject
      language
      identifier
      based_near
      related_url
      source
      downloads
      views
    ]
  end

  def rows
    work_versions.in_batches do |work_version_batch|
      # Load out aggregates of views and downloads for this batch
      views_by_work_version_id = load_views_by_work_version(work_version_batch)
      downloads_by_work_version_id = load_downloads_by_work_version(work_version_batch)

      # Iterate through each work version in this batch, yielding the CSV row
      work_version_batch.each do |wv|
        # Work#latest_published_version will hit the database, which we don't want here
        #latest_published_version = work
        #  .versions
        #  .filter(&:published?)
        #  .max_by(&:version_number)

        views = views_by_work_version_id[wv.id] || 0
        downloads = downloads_by_work_version_id[wv.id] || 0

        row = [
          wv.uuid,
          wv.work.uuid,
          wv.aasm_state,
          wv.version_number,
          wv.title,
          wv.subtitle,
          wv.version_name,
          wv.keyword,
          wv.rights,
          wv.description,
          wv.publisher_statement,
          wv.resource_type,
          wv.contributor,
          wv.publisher,
          wv.published_date,
          wv.subject,
          wv.language,
          wv.identifier,
          wv.based_near,
          wv.related_url,
          wv.source,
          downloads,
          views
        ]

        yield(row)
      end
    end
  end

  private

    def work_versions
      WorkVersion.all
    end

    def works
      Work
        .includes(
          :versions,
          :depositor,
          :access_controls
        )
    end

    # Returns a hash of { work_version_id => num_views }
    def load_views_by_work_version(work_version_batch)
      ViewStatistic
        .joins('INNER JOIN work_versions ON view_statistics.resource_id = work_versions.id')
        .where(
          resource_type: 'WorkVersion',
          work_versions: { id: work_version_batch }
        )
        .group('work_versions.id')
        .sum(:count)
    end

    # Returns a hash of { work_version_id => num_downloads }
    def load_downloads_by_work_version(work_version_batch)
      ViewStatistic
        .joins('INNER JOIN file_version_memberships ON view_statistics.resource_id = file_version_memberships.file_resource_id')
        .joins('INNER JOIN work_versions ON file_version_memberships.work_version_id = work_versions.id')
        .where(
          resource_type: 'FileResource',
          work_versions: { id: work_version_batch }
        )
        .group('work_versions.id')
        .sum(:count)
    end
end
