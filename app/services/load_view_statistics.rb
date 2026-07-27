# frozen_string_literal: true

# @abstract Loads the view statistics for a given model. It returns these
# statistics as a 2d array of raw values, rather than ActiveRecords, for speed.
# The returned rows are ordered by date ascending, and have the structure:
#   [Date, number of views that day, running total of all views through time]
# @example
#   > LoadViewStatistics.call(model: my_model)
#   => [
#        [Date(2020-06-01), 1,     1],
#        [Date(2020-06-02), 100, 101],
#        [Date(2020-06-03), 3,   104]
#      ]

class LoadViewStatistics
  def self.call(model:)
    new(model: model).load_view_statistics
  end

  attr_reader :model,
              :relation

  def initialize(model:)
    @model = model
    @relation = model.view_statistics
  end

  # @return [Array<Array(Date, Integer, Integer)>]
  def load_view_statistics
    sql = query.to_sql

    ViewStatistic
      .connection
      .select_rows(sql)
      .reduce([]) do |accumulator, row|
        raw_date, count = row
        parsed_date = normalize_date(raw_date)
        count ||= 0
        running_total = accumulator.last&.last || 0

        accumulator << [parsed_date, count, running_total + count]
      end
  end

  private

    # Rails/db adapters may return either a String or a Date for date columns.
    def normalize_date(raw_date)
      return raw_date if raw_date.is_a?(Date)

      Date.parse(raw_date.to_s)
    end

    def query
      relation
        .reorder('date ASC')
        .select([:date, :count])
    end
end
