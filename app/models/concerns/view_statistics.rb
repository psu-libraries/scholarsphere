# frozen_string_literal: true

module ViewStatistics
  extend ActiveSupport::Concern

  included do
    has_many :view_statistics,
             as: :resource,
             dependent: :destroy
  end

  def count_view!
    view_statistics
      .find_or_initialize_by(date: Time.zone.today)
      .increment(:count)
      .save
  end

  def stats
    @stats ||= LoadViewStatistics.call(model: self)
  end
end
