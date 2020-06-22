# frozen_string_literal: true

# https://github.com/plataformatec/devise/wiki/OmniAuth:-Overview
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def psu
    @user = User.from_omniauth(request.env['omniauth.auth'])

    sign_in_and_redirect @user, event: :authentication
    set_flash_message(:notice, :success, kind: 'Penn State') if is_navigational_format?
  rescue User::OAuthError => e
    logger.error("\n\n\n#{e.class} (#{e.message}):\n\n")
    logger.error(e.backtrace.join("\n"))
    redirect_to root_path, alert: t('omniauth.login_error')
  end

  def failure
    redirect_to root_path, alert: t('omniauth.login_error')
  end
end
