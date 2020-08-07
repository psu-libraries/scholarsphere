# frozen_string_literal: true

class ActorStatsPresenter
  attr_reader :actor,
              :beginning_at,
              :ending_at

  # @param [Actor] actor
  # @param [Date] beginning_at
  # @param [Date] ending_at
  def initialize(actor:, beginning_at: 100.years.ago, ending_at: Time.zone.now)
    @actor = actor
    @beginning_at = beginning_at
    @ending_at = ending_at
  end

  def display_name
    actor.default_alias
  end

  def file_downloads
    @file_downloads ||= ViewStatistic
      .where(resource_type: 'FileResource', resource_id: file_resource_ids)
      .where('date BETWEEN ? AND ?', beginning_at, ending_at)
      .sum(:count)
  end

  def total_files
    file_resource_ids.count
  end

  private

    # @note Probably ought to look at optimizing this query
    def file_resource_ids
      @file_resource_ids ||= actor.deposited_works.flat_map(&:versions).flat_map(&:file_resource_ids)
    end
end
