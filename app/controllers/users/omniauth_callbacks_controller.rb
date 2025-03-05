# frozen_string_literal: true

# https://github.com/plataformatec/devise/wiki/OmniAuth:-Overview
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  class NotAffiliatedWithPsu < StandardError; end

  def azure_oauth
    @user = User.from_omniauth(request.env['omniauth.auth'])

    raise NotAffiliatedWithPsu unless @user.psu_affiliated?

    sign_in_and_redirect @user, event: :authentication
    set_flash_message(:notice, :success, kind: 'Penn State') if is_navigational_format?
  rescue User::OAuthError => e
    logger.error("\n\n\n#{e.class} (#{e.message}):\n\n")
    logger.error(e.backtrace.join("\n"))
    redirect_to root_path, alert: t('omniauth.login_error')
  rescue NotAffiliatedWithPsu
    redirect_to root_path, alert: t('omniauth.not_affiliated_with_psu') 
  end

  def failure
    redirect_to root_path, alert: t('omniauth.login_error')
  end
end
