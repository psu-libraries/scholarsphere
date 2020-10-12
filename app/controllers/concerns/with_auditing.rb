# frozen_string_literal: true

# @abstract Adds support for auditing controller actions with PaperTrail.

module WithAuditing
  extend ActiveSupport::Concern

  included do
    before_action :set_paper_trail_whodunnit
  end

  # @note Overrides PaperTrail::Rails::Controller to return a global id because our current users are either a User or
  # an ExternalApp.
  def user_for_paper_trail
    return unless defined?(current_user)

    current_user.to_gid
  end
end
