# frozen_string_literal: true

module Admin
  class CurationTicketController < ApplicationController
    def create
      service = LibanswersApiService.new
      response = if params[:ticket_type] == 'curation'
                   service.admin_create_curation_ticket(params[:id])
                 else
                   service.admin_create_accessibility_ticket(params[:id], request.base_url)
                 end
      redirect_to response, allow_other_host: true
    rescue LibanswersApiService::LibanswersApiError => e
      flash[:error] = e.message
      redirect_to edit_dashboard_work_path(id: params[:id])
    end
  end
end
