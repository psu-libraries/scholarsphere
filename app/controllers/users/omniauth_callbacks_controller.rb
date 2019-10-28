# frozen_string_literal: true

# https://github.com/plataformatec/devise/wiki/OmniAuth:-Overview
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def psu
    @user = User.from_omniauth(request.env['omniauth.auth'])

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: 'Penn State') if is_navigational_format?
    else
      # TODO if OAuth fails, where do we went users?
      session['devise.doorkeeper_data'] = request.env['omniauth.auth']
      redirect_to root_path # new_user_registration_url
    end

    def failure
      redirect_to root_path
    end
  end
end
