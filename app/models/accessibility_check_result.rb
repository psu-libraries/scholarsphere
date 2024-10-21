# frozen_string_literal: true

class AccessibilityCheckResult < ApplicationRecord
  validates :report, presence: true

  belongs_to :file_resource
end
