# frozen_string_literal: true

class AllowPublishService
  include AllowPublish

  def self.check(resource)
    new.allow_publish?(resource)
  end
end
