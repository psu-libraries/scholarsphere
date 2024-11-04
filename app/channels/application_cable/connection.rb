# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
      # Log the headers for debugging
      logger.add_tags 'ActionCable', current_user.email if current_user.present?
      logger.info "Remote IP: #{request.headers['REMOTE_ADDR']}"
      logger.info "X-Forwarded-For: #{request.headers['HTTP_X_FORWARDED_FOR']}"
    end

    private

      def find_verified_user
        session = Rails.env.production? ? '_session_id' : '_scholarsphere_session'
        if verified_user = User.find_by(id: cookies.encrypted[session]['warden.user.user.key'][0][0])
          verified_user
        else
          reject_unauthorized_connection
        end
      end
  end
end
