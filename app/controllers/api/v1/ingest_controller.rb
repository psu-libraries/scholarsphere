# frozen_string_literal: true

module Api::V1
  class IngestController < RestController
    rescue_from PennState::SearchService::NotFound do
      render json: depositor_not_found, status: :unprocessable_entity
    end

    def create
      if publisher.errors.any?
        render json: unprocessable_entity_response, status: :unprocessable_entity
      else
        render json: published_response, status: :ok
      end
    end

    private

      def published_response
        {
          message: 'Work was successfully created',
          url: resource_path(publisher.work.uuid)
        }
      end

      def unprocessable_entity_response
        {
          message: 'Unable to complete the request',
          errors: publisher.errors.full_messages + file_errors
        }
      end

      def depositor_not_found
        {
          message: 'Unable to complete the request',
          errors: "Depositor '#{depositor_params}' does not exist"
        }
      end

      # @note Dig down into all the file version memberships and pull out any errors.
      # ** THIS SHOULD PROBABLY BE MOVED INTO WorkPublisher **
      def file_errors
        publisher
          .work
          .versions
          .flat_map { |version| version.file_version_memberships.to_a }
          .flat_map { |membership| membership.errors.full_messages }
      end

      def publisher
        @publisher ||= WorkPublisher.call(
          metadata: metadata_params,
          depositor_access_id: depositor_params,
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
            creators: [
              :display_name,
              :email,
              :given_name,
              :surname,
              :psu_id,
              :orcid
            ]
          )
      end

      def depositor_params
        params
          .require(:depositor)
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
