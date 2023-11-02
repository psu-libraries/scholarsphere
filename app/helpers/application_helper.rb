# frozen_string_literal: true

module ApplicationHelper
  # This is needed by Devise when _not_ using database_authenticatable
  # https://github.com/plataformatec/devise/wiki/OmniAuth:-Overview#using-omniauth-without-other-authentications
  def new_session_path(*_)
    root_path
  end

  def date_display(args)
    Time.zone.parse(args[:document][args[:field]])
      .to_formatted_s(:long)
  end

  def link_to_dropdown_item(link, path, options = {})
    if request.path == path
      link_to link, path, options.merge(class: 'dropdown-item disabled')
    else
      link_to link, path, options.merge(class: 'dropdown-item')
    end
  end

  def link_to_login(link, path, options = {})
    if Rails.application.read_only?
      link_to link, path, options.merge(class: 'nav-link disabled')
    else
      button_to link, path, options.merge(class: 'btn nav-link', style: 'font-weight:600;', type: 'submit')
    end
  end
end
