# frozen_string_literal: true

class ThumbnailUpload < ApplicationRecord
  belongs_to :resource,
             polymorphic: true

  belongs_to :file_resource,
             dependent: :destroy

  validates :resource_id,
            :resource_type,
            :file_resource_id,
            presence: true

  accepts_nested_attributes_for :file_resource
end
