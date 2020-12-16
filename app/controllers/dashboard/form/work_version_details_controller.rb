# frozen_string_literal: true

module Dashboard
  module Form
    class WorkVersionDetailsController < BaseController
      def self._prefixes
        ['application', 'dashboard/form', 'dashboard/form/details']
      end

      def new
        @resource = WorkVersion.build_with_empty_work(depositor: current_user.actor)
      end

      def create
        @resource = WorkVersion.build_with_empty_work(work_version_params, depositor: current_user.actor)
        process_response(on_error: :new)
      end

      def edit
        @resource = WorkVersion.includes(:work).find(params[:id])
        authorize(@resource)
      end

      def update
        @resource = WorkVersion.includes(:work).find(params[:id])
        authorize(@resource)
        @resource.attributes = work_version_params
        process_response(on_error: :edit)
      end

      private

        def work_version_params
          params
            .require(:work_version)
            .permit(
              :title,
              :description,
              :subtitle,
              :rights,
              :version_name,
              :published_date,
              keyword: [],
              contributor: [],
              publisher: [],
              subject: [],
              language: [],
              identifier: [],
              based_near: [],
              related_url: [],
              source: [],
              work_attributes: [
                :id,
                :work_type
              ]
            )
        end

        def next_page_path
          dashboard_form_contributors_path('work_version', @resource.id)
        end
    end
  end
end
