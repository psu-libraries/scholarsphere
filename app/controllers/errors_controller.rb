# frozen_string_literal: true

class ErrorsController < ApplicationController
  def not_found
    render 'not_found', status: :not_found
  end

  def server_error
    render 'server_error', status: :internal_server_error
  end
end
