# frozen_string_literal: true

class CollectionWorkMembership < ApplicationRecord
  belongs_to :collection
  belongs_to :work
end
