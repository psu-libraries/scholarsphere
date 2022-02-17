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
    # Load out aggregates of views and downloads
    views_by_work_id = load_views_by_work
    downloads_by_work_id = load_downloads_by_work

    works.find_each do |work|
      # Work#latest_published_version will hit the database, which we don't want here
      latest_published_version = work
        .versions
        .filter(&:published?)
        .max_by(&:version_number)

      latest_version = work
        .versions
        .reject(&:withdrawn?)
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
    def load_views_by_work
      ViewStatistic
        .joins('INNER JOIN work_versions ON view_statistics.resource_id = work_versions.id')
        .where(
          resource_type: 'WorkVersion'
        )
        .group('work_versions.work_id')
        .sum(:count)
    end

    # Returns a hash of { work_id => num_downloads }
    def load_downloads_by_work
      query = ActiveRecord::Base.sanitize_sql([<<-SQL.squish, resource_type: 'FileResource'])
        SELECT unique_works.work_id AS work_id,
               SUM(view_statistics.count) AS sum_count
        FROM view_statistics
        INNER JOIN (
          SELECT
            DISTINCT work_versions.work_id,
            file_version_memberships.file_resource_id
          FROM work_versions
          INNER JOIN
            file_version_memberships ON file_version_memberships.work_version_id = work_versions.id
          ) unique_works ON unique_works.file_resource_id = view_statistics.resource_id
        WHERE 
          view_statistics.resource_type = :resource_type
        GROUP BY work_id
      SQL

      results = ActiveRecord::Base.connection.exec_query(query)
      results.map { |row| [row['work_id'], row['sum_count']] }.to_h
    end
end
