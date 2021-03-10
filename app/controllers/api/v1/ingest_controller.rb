# frozen_string_literal: true

module Api::V1
  class IngestController < RestController
    def create
      if work.errors.any?
        render json: unprocessable_entity_response, status: :unprocessable_entity
      else
        success_response
      end
    end

    private

      def success_response
        if work.latest_version.published?
          render json: published_response, status: :ok
        else
          render json: draft_response, status: :created
        end
      end

      def published_response
        {
          message: 'Work was successfully created',
          url: resource_path(work.uuid)
        }
      end

      def draft_response
        {
          message: 'Work was created but cannot be published',
          errors: publishing_errors
        }
      end

      # @note Attempt to re-publish the work, then validate it to see what errors there are
      def publishing_errors
        work_version = work.latest_version
        work_version.publish
        work_version.validate
        work_version.errors.full_messages
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
            :embargoed_until,
            :title,
            :subtitle,
            :rights,
            :version_name,
            :published_date,
            :deposited_at,
            :description,
            :doi,
            keyword: [],
            resource_type: [],
            contributor: [],
            publisher: [],
            subject: [],
            language: [],
            identifier: [],
            based_near: [],
            related_url: [],
            source: [],
            creators_attributes: [
              :display_name,
              actor_attributes: [
                :email,
                :given_name,
                :surname,
                :psu_id
              ]
            ]
          )
      end

      def depositor_params
        params
          .require(:depositor)
          .permit(
            :email,
            :given_name,
            :surname,
            :psu_id
          )
      end

      def content_params
        params.fetch(:content, []).map do |content_parameter|
          content_parameter
            .permit(
              :file,
              :deposited_at
            )
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
