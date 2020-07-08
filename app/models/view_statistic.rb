# frozen_string_literal: true

class ViewStatistic < ApplicationRecord
  belongs_to :resource, polymorphic: true

  after_initialize :set_defaults

  private

    def set_defaults
      self.date ||= Time.zone.now
    end
end
