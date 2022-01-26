# frozen_string_literal: true

class UpdateUserActiveStatuses
  class << self
    def call
      User.find_each do |user|
        begin
          user.active = active?(user)
        rescue PsuIdentity::SearchService::NotFound
          user.active = false
        end
        user.save!
      rescue PsuIdentity::SearchService::Error, Net::ReadTimeout, Net::OpenTimeout, SocketError
        next
      end
    end

    private

      def active?(user)
        identity = PsuIdentity::SearchService::Client.new.userid(user.access_id)
        identity.affiliation != ['MEMBER']
      end
  end
end
