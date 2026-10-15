# frozen_string_literal: true

class Users::AuthRedirectController < ApplicationController
  def show
    # Route users here to simulate an "auto-login"
    return_to = params[:return_to].presence
    return unless return_to

    store_location_for(:user, return_to)
    session[:suppress_omniauth_success_notice] = true
  end
end
