# frozen_string_literal: true

class WorkCreation < ApplicationRecord
  belongs_to :alias
  belongs_to :work
end
