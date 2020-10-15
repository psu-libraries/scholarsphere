# frozen_string_literal: true

class Dashboard::BaseController < ApplicationController
  include WithAuditing

  before_action :authenticate_user!

  private

    # Namespace all Pundit calls to dashboard
    # https://github.com/varvet/pundit#policy-namespacing
    def policy(record, *args)
      super([:dashboard, record], *args)
    end

    def policy_scope(scope)
      super([:dashboard, scope])
    end
end
