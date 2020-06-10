# frozen_string_literal: true

class ApiToken < ApplicationRecord
  before_create :set_token

  validates :app_name,
            :admin_email,
            presence: true

  class << self
    # @note Database cleaner and transactional fixtures are causing caching problems so we re-find/create each time but
    # only in test.
    def metadata_listener
      if Rails.env.test?
        find_or_create_metadata_listener
      else
        @metadata_listener ||= find_or_create_metadata_listener
      end
    end

    private

      def find_or_create_metadata_listener
        find_or_create_by(
          app_name: 'Metadata Listener',
          admin_email: 'no-reply@scholarsphere.psu.edu'
        )
      end
  end

  def record_usage
    update_column(:last_used_at, Time.zone.now)
  end

  private

    def set_token
      self.token ||= SecureRandom.hex(48)
    end
end
