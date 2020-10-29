# frozen_string_literal: true

class UserDecorator < SimpleDelegator
  def display_name
    return I18n.t('navbar.guest_name') if guest?
    return I18n.t('navbar.admin_name') if admin?

    "#{name} (#{access_id})"
  end
end
