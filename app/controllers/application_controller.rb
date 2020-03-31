# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  layout :determine_layout if respond_to? :layout

  # Authorization
  include Pundit

  def current_user
    super || User.guest
  end

  def append_info_to_payload(payload)
    super
    payload[:request_id] = request.env["action_dispatch.request_id"]
    payload[:x_forwarded_for] = request.env["HTTP_X_FORWARDED_FOR"]
    payload[:remote_addr] = request.env["REMOTE_ADDR"]
  end
end
