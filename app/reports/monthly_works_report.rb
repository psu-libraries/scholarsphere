# frozen_string_literal: true

class MonthlyWorksReport
  attr_reader :start_date,
              :end_date

  def initialize(date: Time.zone.today)
    @start_date = date.beginning_of_month
    @end_date = date.end_of_month
  end

  def name
    "monthly_works_#{year}-#{month_number(leading_zero: true)}"
  end

  def headers
    %w[
      work_id
      month
      year
      downloads
      views
    ]
  end

  def rows
    works.find_in_batches do |works|
      work_batch_ids = works.map(&:id)
      views_by_work_id = load_views_by_work(work_batch_ids)
      downloads_by_work_id = load_downloads_by_work(work_batch_ids)

      works.each do |work|
        views = views_by_work_id[work.id] || 0
        downloads = downloads_by_work_id[work.id] || 0

        yield(generate_row(work: work, views: views, downloads: downloads))
      end
    end
  end

  private

    def month_number(leading_zero: false)
      start_date.strftime(leading_zero ? '%m' : '%-m')
    end

    def year
      start_date.strftime('%Y')
    end

    def works
      Work
        .includes(:access_controls)
    end

    def generate_row(work:, views:, downloads:)
      [
        work.uuid,
        month_number,
        year,
        downloads,
        views
      ]
    end

    # Returns a hash of { work_id => num_views }
    # @note this is almost duplicate of the one in AllWorksReport with
    # additional conditionals for start and end dates. Possible refactor
    def load_views_by_work(work_batch_ids)
      ViewStatistic
        .joins('INNER JOIN work_versions ON view_statistics.resource_id = work_versions.id')
        .where(
          resource_type: 'WorkVersion',
          date: (start_date..end_date),
          work_versions: { work_id: work_batch_ids }
        )
        .group('work_versions.work_id')
        .sum(:count)
    end

    # Returns a hash of { work_id => num_downloads }
    # @note this is almost duplicate of the one in AllWorksReport with
    # additional conditionals for start and end dates. Possible refactor
    def load_downloads_by_work(work_batch_ids)
      raw_query = <<-SQL.squish
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
        WHERE#{' '}
          view_statistics.resource_type = :resource_type
        AND
          work_id IN(:work_ids)
        AND
          view_statistics.date BETWEEN :start_date AND :end_date
        GROUP BY work_id
      SQL

      query = ActiveRecord::Base.sanitize_sql([raw_query,
                                               { resource_type: 'FileResource',
                                                 work_ids: work_batch_ids,
                                                 start_date: start_date, end_date: end_date }])
      results = ActiveRecord::Base.connection.exec_query(query)
      results.map { |row| [row['work_id'], row['sum_count']] }.to_h
    end
end
