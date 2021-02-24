# frozen_string_literal: true

class ActorStatsPresenter
  attr_reader :actor,
              :beginning_at,
              :ending_at

  delegate :display_name, to: :actor

  # @param [Actor] actor
  # @param [Date] beginning_at
  # @param [Date] ending_at
  def initialize(actor:, beginning_at: 100.years.ago, ending_at: Time.zone.now)
    @actor = actor
    @beginning_at = beginning_at
    @ending_at = ending_at
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

    def file_resource_ids
      @file_resource_ids ||= FileVersionMembership
        .joins(work_version: [:work])
        .where(works: { depositor_id: actor.id })
        .pluck(:file_resource_id)
    end
end
