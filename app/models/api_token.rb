# frozen_string_literal: true

class ApiToken < ApplicationRecord
  before_create :set_token

  validates :app_name,
            :admin_email,
            presence: true

  def record_usage
    update_column(:last_used_at, Time.zone.now)
  end

  private

    def set_token
      self.token ||= SecureRandom.hex(48)
    end
end
