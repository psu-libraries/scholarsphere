# frozen_string_literal: true

module Dashboard
  module Form
    class MembersController < BaseController
      def edit
        @resource = Collection
          .includes(collection_work_memberships: [:work])
          .find(params[:id])
        authorize(@resource)
      end

      def update
        @resource = Collection.find(params[:id])
        authorize(@resource)
        @resource.attributes = collection_params
        process_response(on_error: :edit)
      end

      private

        def collection_params
          return {} unless params.key?(:collection)

          params
            .require(:collection)
            .permit(
              collection_work_memberships_attributes: [
                :id,
                :work_id,
                :_destroy,
                :position
              ]
            )
        end
    end
  end
end
