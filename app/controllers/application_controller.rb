# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  layout 'frontend'

  # Authorization
  include Pundit

  ActionDispatch::ExceptionWrapper.rescue_responses['Pundit::NotAuthorizedError'] = :not_found

  before_action do
    Rack::MiniProfiler.authorize_request if current_user.admin?
  end

  # The callback which stores the current location must be added before you authenticate the user
  # as `authenticate_user!`  will halt the filter chain and redirect before the location can be stored.
  before_action :store_user_location!, if: :storable_location?

  def current_user
    return User.guest if Rails.application.read_only?

    UserDecorator.new(super || User.guest)
  end

  helper_method :show_footer?
  def show_footer?
    true
  end

  private

    # Its important that the location is NOT stored if:
    # - The request method is not GET (non idempotent)
    # - The request is handled by a Devise controller such as Devise::SessionsController as that could cause an
    #    infinite redirect loop.
    # - The request is an Ajax request as this can lead to very unexpected behaviour.
    def storable_location?
      request.get? && is_navigational_format? && !devise_controller? && !request.xhr?
    end

    def store_user_location!
      # :user is the scope we are authenticating
      store_location_for(:user, request.fullpath)
    end
end
