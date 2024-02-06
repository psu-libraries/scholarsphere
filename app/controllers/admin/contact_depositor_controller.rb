# frozen_string_literal: true

module Admin
  class ContactDepositorController < ApplicationController
    def form
      work = Work.find(params[:id])
      @contact_depositor_form = AdminContactDepositor.new(send_to_name: work.depositor.display_name, 
                                                          send_to_email: work.depositor.email, 
                                                          cc_email_to: work.edit_users.collect(&:email) << work.depositor.email)
    end

    def submit
      @contact_depositor_form = AdminContactDepositor.new(contact_depositor_params.to_h)
      if @contact_depositor_form.valid?
        response = LibanswersApiService.new(contact_depositor_params.to_h).create_ticket
        redirect_to response
      else
        render :form
      end
    rescue LibanswersApiService::LibanswersAPIError => e
      flash[:error] = e.message
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
