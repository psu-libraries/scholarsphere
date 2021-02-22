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
      link_to link, path, options.merge(class: 'nav-link')
    end
  end

  # @note Based off of ActionView::Helpers::Tags::Base#tag_id. Because it's a private method, and we shouldn't override
  # it, we're redoing it here.
  def form_field_id(form, attribute)
    sanitized_object_name = form.object_name
      .gsub(/\]\[|[^-a-zA-Z0-9:.]/, '_') # Replace non-alphanumerics with '_'
      .sub(/_$/, '')                     # Remove a trailing '_'
    [sanitized_object_name, attribute.to_s].join('_')
  end
end
