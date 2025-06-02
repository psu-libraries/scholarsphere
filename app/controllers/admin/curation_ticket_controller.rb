# frozen_string_literal: true

module Admin
  class CurationTicketController < ApplicationController
    def create_work
      service = LibanswersApiService.new
      response = if params[:ticket_type] == 'curation'
                   service.admin_create_ticket(params[:id], 'work_curation')
                 else
                   service.admin_create_ticket(params[:id], 'work_accessibility', request.base_url)
                 end
      redirect_to response, allow_other_host: true
    rescue LibanswersApiService::LibanswersApiError => e
      flash[:error] = e.message
      redirect_to edit_dashboard_work_path(id: params[:id])
    end

    def create_collection
      service = LibanswersApiService.new
      response = service.admin_create_ticket(params[:id], 'collection')
      redirect_to response, allow_other_host: true
    rescue LibanswersApiService::LibanswersApiError => e
      flash[:error] = e.message
      redirect_to edit_dashboard_work_path(id: params[:id])
    end
  end
end
