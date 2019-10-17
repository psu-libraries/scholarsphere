# frozen_string_literal: true

class AccessControl < ApplicationRecord
  belongs_to :agent,
             polymorphic: true
  belongs_to :resource,
             polymorphic: true
end
