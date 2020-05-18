# frozen_string_literal: true

module Api::V1
  class CollectionsController < RestController
    rescue_from StandardError do |exception|
      if exception.is_a?(ActionController::ParameterMissing)
        render json: { message: 'Bad request', errors: [exception.message] }, status: :bad_request
      else
        render json: { message: "We're sorry, but something went wrong", errors: [exception.class.to_s, exception] },
               status: :internal_server_error
      end
    end

    before_action :return_migrated_collection

    def create
      if collection.errors.any?
        render json: unprocessable_entity_response, status: :unprocessable_entity
      else
        render json: success_response, status: :ok
      end
    end

    private

      def return_migrated_collection
        ids = LegacyIdentifier.where(old_id: metadata_params['noid'], version: 3, resource_type: 'Collection')
        return if ids.empty?

        collection = Collection.find(ids.first.resource_id)
        render json: migrated_response(collection), status: 303
      end

      def migrated_response(collection)
        {
          message: 'Collection has already been migrated',
          url: resource_path(collection.uuid)
        }
      end

      def success_response
        {
          message: 'Collection was successfully created',
          url: resource_path(collection.uuid)
        }
      end

      def unprocessable_entity_response
        {
          message: 'Unable to complete the request',
          errors: collection.errors.full_messages
        }
      end

      def collection
        @collection ||= CreateNewCollection.call(
          metadata: metadata_params.merge!(work_ids: work_ids),
          depositor: depositor_params,
          permissions: permission_params
        )
      end

      # @note Noids are globally unique in Scholarsphere 3, so limiting this query to collections isn't necessary.
      def work_ids
        work_noid_params.map { |noid| LegacyIdentifier.find_by!(old_id: noid).resource_id }
          .concat(metadata_params.fetch(:work_ids, []))
          .uniq
      end

      def metadata_params
        params
          .require(:metadata)
          .permit(
            :title,
            :subtitle,
            :rights,
            :noid,
            work_ids: [],
            keyword: [],
            description: [],
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

      def work_noid_params
        params.fetch(:work_noids, [])
      end
  end
end