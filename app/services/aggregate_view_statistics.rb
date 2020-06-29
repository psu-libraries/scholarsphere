# frozen_string_literal: true

# @abstract Loads the view statistics for an array of models. It returns these
# statistics as a 2d array, sorted by date ascenting, just like LoadViewStatistics:
#   [Date, number of views that day, running total of all views through time]
# @example
#   > AggregateViewStatistics.call(models: [model_1, model_2])
#   => [
#        [Date(2020-06-01), 1,     1],
#        [Date(2020-06-02), 100, 101],
#        [Date(2020-06-03), 3,   104]
#      ]
class AggregateViewStatistics
  def self.call(models:)
    new(models: models).load_view_statistics
  end

  attr_reader :models

  def initialize(models:)
    @models = models
  end

  def load_view_statistics
    date_historgram = Hash.new(0)

    models.each do |model|
      stats = ::LoadViewStatistics.call(model: model)

      stats.each do |date, count, _total|
        date_historgram[date] = date_historgram[date] + count
      end
    end

    date_historgram
      .to_a
      .sort_by { |date, _count| date }
      .reduce([]) do |accumulator, row|
        date, count = row
        running_total = accumulator.last&.last || 0
        accumulator << [date, count, running_total + count]
      end
  end
end
