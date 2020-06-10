# frozen_string_literal: true

module Api
  module V1
    class RestController < ActionController::API
      before_action :authenticate_request!

      rescue_from StandardError do |exception|
        logger.error("\n\n\n#{exception.class} (#{exception.message}):\n\n")
        logger.error(exception.backtrace.join("\n"))
        if exception.is_a?(ActionController::ParameterMissing)
          render json: { message: 'Bad request', errors: [exception.message] }, status: :bad_request
        elsif exception.is_a?(ActiveRecord::RecordNotFound)
          render json: { message: 'Record not found' }, status: :not_found
        else
          render json: { message: "We're sorry, but something went wrong", errors: [exception.class.to_s, exception] },
                 status: :internal_server_error
        end
      end

      private

        def authenticate_request!
          if api_token
            api_token.record_usage
          else
            render json: { message: I18n.t('api.errors.not_authorized'), code: 401 }, status: 401 unless api_token
          end
        end

        def api_token
          @api_token ||= ApiToken.find_by(token: api_key_header)
        end

        def api_key_header
          request.headers['HTTP_X_API_KEY'].presence ||
            request.headers['X_API_KEY']
        end
    end
  end
end
