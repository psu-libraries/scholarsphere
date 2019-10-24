# frozen_string_literal: true

module ApplicationHelper
  # This is needed by Devise when _not_ using database_authenticatable
  # https://github.com/plataformatec/devise/wiki/OmniAuth:-Overview#using-omniauth-without-other-authentications
  def new_session_path(*_)
    new_user_session_path
  end

  # TODO Blacklight's default configuration/views require this path helper to be
  # present. Since we are using OAuth exclusively and are not currently using
  # Devise database_authenticatable, this path helper does not exist, causing
  # Blacklight to freak out.
  def edit_user_registration_path
    '/'
  end
end
