# frozen_string_literal: true

class Dashboard::BaseController < ApplicationController
  include WithAuditing

  before_action :authenticate_user!
end
