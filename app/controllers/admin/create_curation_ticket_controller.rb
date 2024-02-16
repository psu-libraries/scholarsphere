# frozen_string_literal: true

module Admin
  class CreateCurationTicketController < ApplicationController
    def submit
      response = LibanswersApiService.new(params[:id]).admin_create_curation_ticket
      redirect_to response
    rescue LibanswersApiService::LibanswersApiError => e
      flash[:error] = e.message
      redirect_to edit_dashboard_work_path(id: params[:id])
    end
  end
end
