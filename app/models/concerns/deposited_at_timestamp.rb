# frozen_string_literal: true

module DepositedAtTimestamp
  extend ActiveSupport::Concern

  included do
    validates :deposited_at,
              presence: true

    after_initialize :set_deposited_at
  end

  private

    def set_deposited_at
      self.deposited_at ||= Time.zone.now
    end
end
