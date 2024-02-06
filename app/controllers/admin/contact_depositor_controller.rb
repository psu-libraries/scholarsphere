# frozen_string_literal: true

module Admin
  class ContactDepositorController < ApplicationController
    def form
      resource = resource_klass.find(params[:id])
      @contact_depositor_form = AdminContactDepositor.new(send_to_name: resource.depositor.display_name, 
                                                          send_to_email: resource.depositor.email, 
                                                          cc_email_to: resource.edit_users.collect(&:email) << resource.depositor.email)
    end

    def submit
      response = LibanswersApiService.new(contact_depositor_params.to_h).create_ticket
      redirect_to response
    rescue LibanswersApiService::LibanswersAPIError => e
      flash[:error] = e.message
      @contact_depositor_form = AdminContactDepositor.new(contact_depositor_params.to_h)
      render :form
    end

    private

    def contact_depositor_params
      params
        .require(:admin_contact_depositor)
        .permit(
          :send_to_name,
          :send_to_email,
          :subject,
          :message,
          cc_email_to: []
        )
    end

    def resource_klass
      case params[:resource_klass]
      when 'work'
        Work
      when 'collection'
        Collection
      else
        @resource.class
      end
    end
  end
end
