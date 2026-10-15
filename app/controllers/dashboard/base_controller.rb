# frozen_string_literal: true

class Dashboard::BaseController < ApplicationController
  include WithAuditing

  before_action :authenticate_dashboard_user

  private

    def authenticate_dashboard_user
      redirect_to root_path if Rails.application.read_only?

      if current_user.guest? && files_edit_request?
        redirect_to user_azure_oauth_redirect_path(return_to: request.fullpath)
        return
      end

      authenticate_user!
    end

    def files_edit_request?
      params[:controller] == 'dashboard/form/files' && params[:action] == 'edit'
    end
end
