# frozen_string_literal: true

class FeaturedResource < ApplicationRecord
  belongs_to :resource,
             polymorphic: true

  validates :resource_uuid,
            presence: true
end
