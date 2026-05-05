# frozen_string_literal: true

module Admin
  class CurationTicketController < ApplicationController
    def create_work
      service = LibanswersApiService.new
      response = if params[:ticket_type] == 'curation'
                   service.curate_work_ticket(params[:id])
                 else
                   service.accessibility_check_ticket(params[:id])
                 end
      redirect_to response, allow_other_host: true
    rescue LibanswersApiService::LibanswersApiError => e
      flash[:error] = e.message
      redirect_to edit_dashboard_work_path(id: params[:id])
    end

    def create_collection
      service = LibanswersApiService.new
      response = service.curate_collection_ticket(params[:id])
      redirect_to response, allow_other_host: true
    rescue LibanswersApiService::LibanswersApiError => e
      flash[:error] = e.message
      redirect_to edit_dashboard_work_path(id: params[:id])
    end
  end
end
