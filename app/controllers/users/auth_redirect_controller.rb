# frozen_string_literal: true

class Users::AuthRedirectController < ApplicationController
  def show
    return_to = params[:return_to].presence
    store_location_for(:user, return_to) if return_to
    session[:suppress_omniauth_success_notice] = true
  end
end
