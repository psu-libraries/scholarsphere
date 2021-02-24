# frozen_string_literal: true

class ApplicationSetting < ApplicationRecord
  before_create :enforce_singleton

  def self.instance
    first || create
  end

  private

    def enforce_singleton
      return if self.class.count.zero?

      raise ArgumentError, "#{self.class} is a singleton"
    end
end
