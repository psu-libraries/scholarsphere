# frozen_string_literal: true

module Api
  class PublicController < V1::RestController
    # POST /api/public
    def execute
      render json: Schema.execute(
        params[:query],
        variables: variables,
        context: context,
        operation_name: params[:operationName]
      )
    end

    private

      def authenticate_request!
        api_token.record_usage if api_token && !Rails.application.read_only?
      end

      def context
        {
          user: current_user
        }
      end

      def variables
        if variables_param.is_a?(String)
          JSON.parse(variables_param)
        else
          variables_param
        end
      rescue JSON::ParserError
        {}
      end

      def variables_param
        @variables_param ||= params.fetch(:variables, {})
      end
  end
end
