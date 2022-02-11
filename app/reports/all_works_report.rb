# frozen_string_literal: true

class AllWorksReport
  def name
    'all_works'
  end

  def headers
    %w[
      id
      depositor
      work_type
      title
      doi
      deposited_at
      deposit_agreed_at
      embargoed_until
      visibility
      latest_published_version
      downloads
      views
    ]
  end

  def rows
    works.in_batches do |works_batch|
      # Load out aggregates of views and downloads for this batch
      views_by_work_id = load_views_by_work(works_batch)
      downloads_by_work_id = load_downloads_by_work(works_batch)

      # Iterate through each work in this batch, yielding the CSV row
      works_batch.each do |work|
        # Work#latest_published_version will hit the database, which we don't want here
        latest_published_version = work
          .versions
          .filter(&:published?)
          .max_by(&:version_number)

        latest_version = work
          .versions
          .max_by(&:version_number)

        views = views_by_work_id[work.id] || 0
        downloads = downloads_by_work_id[work.id] || 0

        row = [
          work.uuid,
          work.depositor.psu_id,
          work.work_type,
          latest_version.title,
          work.doi,
          work.deposited_at,
          work.deposit_agreed_at,
          work.embargoed_until,
          work.visibility,
          latest_published_version&.uuid,
          downloads,
          views
        ]

        yield(row)
      end
    end
  end

  private

    def works
      Work
        .includes(
          :versions,
          :depositor,
          :access_controls
        )
        .order(id: :asc)
    end

    # Returns a hash of { work_id => num_views }
    def load_views_by_work(work_batch)
      ViewStatistic
        .joins('INNER JOIN work_versions ON view_statistics.resource_id = work_versions.id')
        .where(
          resource_type: 'WorkVersion',
          work_versions: { work_id: work_batch }
        )
        .group('work_versions.work_id')
        .sum(:count)
    end

    # Returns a hash of { work_id => num_downloads }
    def load_downloads_by_work(work_batch)
      ViewStatistic
        .joins('INNER JOIN file_version_memberships ON view_statistics.resource_id = file_version_memberships.file_resource_id')
        .joins('INNER JOIN work_versions ON file_version_memberships.work_version_id = work_versions.id')
        .where(
          resource_type: 'FileResource',
          work_versions: { work_id: work_batch }
        )
        .group('work_versions.work_id')
        .sum(:count)

##ViewStatistic.joins('INNER JOIN file_version_memberships ON view_statistics.resource_id = file_version_memberships.file_resource_id').joins('INNER JOIN work_versions ON file_version_memberships.work_version_id = work_versions.id').where(  resource_type: 'FileResource').group('work_versions.work_id').sum(:count)
    end
end
