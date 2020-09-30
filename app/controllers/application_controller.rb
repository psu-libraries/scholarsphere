# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  layout :determine_layout if respond_to? :layout

  # Authorization
  include Pundit

  def current_user
    UserDecorator.new(super || User.guest)
  end

  helper_method :show_footer?
  def show_footer?
    true
  end
end
