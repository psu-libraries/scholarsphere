# frozen_string_literal: true

module Dashboard
  module Form
    class CollectionDetailsController < BaseController
      def self._prefixes
        ['application', 'dashboard/form', 'dashboard/form/details']
      end

      def new
        @resource = new_collection(depositor: current_user.actor)
      end

      def create
        @resource = new_collection(collection_params.merge(depositor: current_user.actor))
        process_response(on_error: :new)
      end

      def edit
        @resource = Collection.find(params[:id])
        authorize(@resource)
      end

      def update
        @resource = Collection.find(params[:id])
        authorize(@resource)
        @resource.attributes = collection_params
        process_response(on_error: :edit)
      end

      def destroy
        @resource = Collection.find(params[:id])
        authorize(@resource)
        @resource.destroy
        respond_to do |format|
          format.html { redirect_to dashboard_root_path, notice: 'Collection was successfully deleted.' }
        end
      end

      private

        def new_collection(attrs = {})
          current_user.actor.deposited_collections.build(attrs)
        end

        def collection_params
          params
            .require(:collection)
            .permit(
              :title,
              :description,
              :subtitle,
              :published_date,
              keyword: [],
              contributor: [],
              publisher: [],
              subject: [],
              language: [],
              identifier: [],
              based_near: [],
              related_url: [],
              source: []
            )
        end

        def next_page_path
          dashboard_form_contributors_path('collection', @resource)
        end
    end
  end
end
