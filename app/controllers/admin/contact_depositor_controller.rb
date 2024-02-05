# frozen_string_literal: true

module Admin
  class ContactDepositorController < ApplicationController
    def form
      resource = resource_klass.find(params[:id])
      @contact_depositor_form = AdminContactDepositor.new(send_to_name: resource.depositor.display_name, 
                                                          send_to_email: resource.depositor.email, 
                                                          cc_email_to: resource.edit_users.collect(&:email) << resource.depositor.email)
    end

    private

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
