# frozen_string_literal: true

module Api::V1
  class IngestController < RestController
    rescue_from ActionController::ParameterMissing do |exception|
      render json: { message: 'Bad request', errors: [exception.message] }, status: :bad_request
    end

    def create
      if work.errors.any?
        render json: unprocessable_entity_response, status: :unprocessable_entity
      else
        render json: success_response, status: :ok
      end
    end

    private

      def success_response
        {
          message: 'Work was successfully created',
          url: resource_path(work.uuid)
        }
      end

      def unprocessable_entity_response
        {
          message: 'Unable to complete the request',
          errors: work.errors.full_messages + file_errors
        }
      end

      # @note Dig down into all the file version memberships and pull out any errors.
      def file_errors
        work
          .versions
          .flat_map { |version| version.file_version_memberships.to_a }
          .flat_map { |membership| membership.errors.full_messages }
      end

      def work
        @work ||= PublishNewWork.call(
          metadata: metadata_params,
          depositor: depositor_params,
          content: content_params,
          permissions: permission_params
        )
      end

      def metadata_params
        params
          .require(:metadata)
          .permit(
            :work_type,
            :visibility,
            :title,
            :subtitle,
            :rights,
            :version_name,
            keyword: [],
            description: [],
            resource_type: [],
            contributor: [],
            publisher: [],
            published_date: [],
            subject: [],
            language: [],
            identifier: [],
            based_near: [],
            related_url: [],
            source: [],
            creator_aliases_attributes: [
              :alias,
              creator_attributes: [
                :email,
                :given_name,
                :surname,
                :psu_id
              ]
            ]
          )
      end

      def depositor_params
        params.require(:depositor)
      end

      def content_params
        params.require(:content).map do |content_parameter|
          content_parameter.permit(:file)
        end
      end

      def permission_params
        params.fetch(:permissions, {})
          .permit(
            edit_users: [],
            edit_groups: [],
            read_users: [],
            read_groups: [],
            discover_users: [],
            discover_group: []
          )
      end
  end
end
