# frozen_string_literal: true

class FindResource
  def self.call(uuid)
    Work.where(uuid: uuid).first ||
      WorkVersion.where(uuid: uuid).first ||
      Collection.where(uuid: uuid).first ||
      raise(ActiveRecord::RecordNotFound)
  end
end
