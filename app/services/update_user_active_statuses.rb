# frozen_string_literal: true

class UpdateUserActiveStatuses
  def self.call
    User.find_each do |user|
      begin
        identity = PsuIdentity::SearchService::Client.new.userid(user.access_id)
        user.active = (identity.affiliation != ['MEMBER'])
      rescue PsuIdentity::SearchService::NotFound
        user.active = false
      end
      user.save!
    rescue PsuIdentity::SearchService::Error, Net::ReadTimeout, Net::OpenTimeout, SocketError
      next
    end
  end
end
