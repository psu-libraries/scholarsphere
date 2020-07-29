# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  def new
    redirect_to user_azure_oauth_omniauth_authorize_path
  end
end
