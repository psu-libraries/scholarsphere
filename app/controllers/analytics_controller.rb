# frozen_string_literal: true

class AnalyticsController < ApplicationController
  def show
    resource = FindResource.call(params[:resource_id])
    view_statistics = load_view_statistics(resource)

    respond_to do |format|
      format.html { head :unsupported_media_type }
      format.json { render json: view_statistics }
    end
  rescue ActiveRecord::RecordNotFound
    head 404, content_type: 'text/plain'
  end

  private

    def load_view_statistics(resource)
      resource
        .stats
        .map { |date, count, total| [date.iso8601, count, total] }
    end
end
