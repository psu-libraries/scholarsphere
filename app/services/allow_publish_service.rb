class AllowPublishService
    include AllowPublish
  
    def self.check(resource)
      new.allow_publish?(resource)
    end
  end