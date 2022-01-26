# frozen_string_literal: true

class UpdateUserActiveStatuses
  class << self
    def call
      User.find_each do |user|
        user.active = active?(user)
        user.save!
      rescue PsuIdentity::SearchService::Error, Net::ReadTimeout, Net::OpenTimeout, SocketError
        next
      end
    end

    private

      def active?(user)
        identity = PsuIdentity::SearchService::Client.new.userid(user.access_id)
        identity.affiliation != ['MEMBER']
      rescue PsuIdentity::SearchService::NotFound
        false
      end
  end
end
