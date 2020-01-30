# frozen_string_literal: true

module Api
  module V1
    class RestController < ActionController::Base
      skip_forgery_protection
    end
  end
end
