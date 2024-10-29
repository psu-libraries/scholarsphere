# frozen_string_literal: true

class AccessibilityCheckResult < ApplicationRecord
  belongs_to :file_resource

  validates :detailed_report, presence: true
end
