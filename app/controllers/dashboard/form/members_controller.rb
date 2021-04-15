# frozen_string_literal: true

module Dashboard
  module Form
    class MembersController < BaseController
      def edit
        @resource = Collection
          .includes(collection_work_memberships: [:work])
          .find(params[:id])
        (@member_works, _deprecated_document_list) = search_service.search_results
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

        def search_service
          @search_service ||= ::Blacklight::SearchService.new(
            config: Blacklight::Configuration.new,
            search_builder_class: MemberWorksSearchBuilder,
            current_user: current_user,
            max_documents: 10_000
          )
        end
    end
  end
end
