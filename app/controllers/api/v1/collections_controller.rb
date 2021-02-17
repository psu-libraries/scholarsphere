# frozen_string_literal: true

module Api::V1
  class CollectionsController < RestController
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
          metadata: metadata_params,
          depositor: depositor_params,
          permissions: permission_params,
          work_noids: work_noid_params
        )
      end

      def metadata_params
        params
          .require(:metadata)
          .permit(
            :title,
            :subtitle,
            :rights,
            :noid,
            :published_date,
            :deposited_at,
            :description,
            :doi,
            work_ids: [],
            keyword: [],
            contributor: [],
            publisher: [],
            subject: [],
            language: [],
            identifier: [],
            based_near: [],
            related_url: [],
            source: [],
            creators_attributes: [
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
