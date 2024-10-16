# frozen_string_literal: true

class AccessibilityCheckResult < ApplicationRecord
  belongs_to :file_resource

  validates :detailed_report, presence: true

  def score
    "#{num_passed} out of #{num_total} passed"
  end

  def failures_present?
    num_passed != num_total
  end

  private

    def num_passed
      detailed_report.values.flatten.count { |rule| rule['Status'] == 'Passed' }
    end

    def num_total
      detailed_report.values.flatten.count
    end
end
