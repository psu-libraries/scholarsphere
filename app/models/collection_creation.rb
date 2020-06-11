# frozen_string_literal: true

class CollectionCreation < ApplicationRecord
  belongs_to :collection,
             inverse_of: :creator_aliases

  belongs_to :actor,
             inverse_of: :collection_creations

  accepts_nested_attributes_for :actor

  validates :alias,
            presence: true

  after_initialize :set_defaults

  private

    def set_defaults
      self.alias ||= actor&.default_alias
    end
end
