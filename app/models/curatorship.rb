class Curatorship < ApplicationRecord
    belongs_to :user
    belongs_to :work
  
    def access_id
      self.user.access_id
    end
  end