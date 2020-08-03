# frozen_string_literal: true

module ApplicationHelper
  # This is needed by Devise when _not_ using database_authenticatable
  # https://github.com/plataformatec/devise/wiki/OmniAuth:-Overview#using-omniauth-without-other-authentications
  def new_session_path(*_)
    new_user_session_path
  end

  def date_display(args)
    Time.zone.parse(args[:document][args[:field]])
      .to_formatted_s(:long)
  end

  def home?
    current_page?('/')
  end
end
