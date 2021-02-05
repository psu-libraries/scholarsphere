# frozen_string_literal: true

class Dashboard::BaseController < ApplicationController
  include WithAuditing

  before_action :authenticate_dashboard_user

  private

    def authenticate_dashboard_user
      redirect_to root_path if Rails.application.read_only?

      authenticate_user!
    end
end
