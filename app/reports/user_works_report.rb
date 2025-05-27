# frozen_string_literal: true

class UserWorksReport < MonthlyWorksReport
  attr_reader :depositor

  def initialize(actor:, start_date:, end_date:)
    raise ArgumentError, 'you must give me an Actor' unless actor.is_a? Actor

    @start_date = start_date
    @end_date = end_date
    @depositor = actor
  end

  def name
    "works_#{depositor.psu_id}_#{start_date}_to_#{end_date}"
  end

  def headers
    %w[
      work_id
      title
      downloads
      views
    ]
  end

  private

    def works
      super
        .includes(:versions)
        .where(depositor_id: depositor)
    end

    def generate_row(work:, views:, downloads:)
      latest_version = work
        .versions
        .reject(&:withdrawn?)
        .max_by(&:version_number)

      title = latest_version&.title

      [
        work.uuid,
        title,
        downloads,
        views
      ]
    end
end
