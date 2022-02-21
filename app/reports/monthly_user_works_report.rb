# frozen_string_literal: true

class MonthlyUserWorksReport < MonthlyWorksReport
  attr_reader :depositor

  def initialize(actor:, date: Time.zone.today)
    raise ArgumentError, 'you must give me an Actor' unless actor.is_a? Actor

    super(date: date)
    @depositor = actor
  end

  def name
    "monthly_works_#{depositor.psu_id}_#{year}-#{month_number(leading_zero: true)}"
  end

  def headers
    %w[
      work_id
      title
      month
      year
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

      title = latest_version.title

      [
        work.uuid,
        title,
        month_number,
        year,
        downloads,
        views
      ]
    end
end
