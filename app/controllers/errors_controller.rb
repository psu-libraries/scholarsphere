# frozen_string_literal: true

class ErrorsController < ApplicationController
  def not_found
    respond_to do |format|
      format.html { render 'not_found', status: :not_found }
      format.any { render json: { message: 'Record not found' }, status: :not_found }
    end
  end

  def server_error
    respond_to do |format|
      format.html { render 'server_error', status: :internal_server_error }
      format.any { render json: { message: 'Server error' }, status: :internal_server_error }
    end
  end
end
