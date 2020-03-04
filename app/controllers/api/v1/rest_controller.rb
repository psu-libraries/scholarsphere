# frozen_string_literal: true

module Api
  module V1
    class RestController < ActionController::Base
      skip_forgery_protection
      before_action :authenticate_request!

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
