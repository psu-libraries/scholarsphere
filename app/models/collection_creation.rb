# frozen_string_literal: true

class CollectionCreation < ApplicationRecord
  belongs_to :collection,
             inverse_of: :creator_aliases

  belongs_to :actor,
             inverse_of: :collection_creations

  accepts_nested_attributes_for :actor

  validates :alias,
            presence: true

  def alias
    super.presence || actor&.default_alias
  end
end
