# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  layout 'frontend'

  # Authorization
  include Pundit

  ActionDispatch::ExceptionWrapper.rescue_responses['Pundit::NotAuthorizedError'] = :not_found

  def current_user
    return User.guest if Rails.application.read_only?

    UserDecorator.new(super || User.guest)
  end

  helper_method :show_footer?
  def show_footer?
    true
  end
end
