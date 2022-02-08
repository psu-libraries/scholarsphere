# frozen_string_literal: true

require 'csv'

class Dashboard::ReportsController < Dashboard::BaseController
  def show
  end

  def all_works
    headers = [
      'id',
      'depositor',
      'work_type',
      'title',
      'doi',
      'deposited_at',
      'deposit_agreed_at',
      'embargoed_until',
      'visibility',
      'latest_published_version',
      'downloads',
      'views'
    ]

    works = Work
      .includes(:versions, :depositor, :access_controls)

    # TODO I think there is a cleaner way to do this, but this works
    all_views_by_work_id = ViewStatistic
      .where(resource_type: 'WorkVersion')
      .joins('INNER JOIN work_versions ON view_statistics.resource_id = work_versions.id')
      .group('work_versions.work_id')
      .sum(:count)

    all_downloads_by_work_id = ViewStatistic
      .where(resource_type: 'FileResource')
      .joins('INNER JOIN file_version_memberships ON view_statistics.resource_id = file_version_memberships.work_version_id')
      .joins('INNER JOIN work_versions ON file_version_memberships.work_version_id = work_versions.id')
      .group('work_versions.work_id')
      .sum(:count)

    result = ::CSV.generate(headers: true) do |csv|
      csv << headers

      works.find_each do |work|
        # Work#latest_published_version will hit the database, which we don't want here
        latest_published_version = work
              .versions
              .filter(&:published?)
              .sort_by(&:version_number)
              .last

        latest_version = work
              .versions
              .sort_by(&:version_number)
              .last

        views = all_views_by_work_id[work.id] || 0
        downloads = all_downloads_by_work_id[work.id] || 0

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

        csv << row
      end
    end

    send_data result, filename: 'report.csv'
  end
end
