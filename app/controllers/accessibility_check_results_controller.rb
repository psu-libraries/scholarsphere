# frozen_string_literal: true

class AccessibilityCheckResultsController < ApplicationController
  def show
    @result = AccessibilityCheckResult.find(params[:id])
    @report = @result.formatted_report
    @title = @result.file_resource.file_data['metadata']['filename']
  end
end
