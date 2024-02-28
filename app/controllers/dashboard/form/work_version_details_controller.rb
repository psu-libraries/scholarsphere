# frozen_string_literal: true

module Dashboard
  module Form
    class WorkVersionDetailsController < BaseController
      def self._prefixes
        ['application', 'dashboard/form', 'dashboard/form/details']
      end

      def edit
        authorize(work_version)
        @resource = deposit_pathway.details_form
        @autocomplete_work_form = AutocompleteWorkForm.new
      end

      def update
        authorize(work_version)
        @resource = deposit_pathway.details_form
        @resource.attributes = work_version_params
        process_response(on_error: :edit)
      end

      def autocomplete_work_forms
        authorize(work_version, :edit?)
        @resource = work_version
        @resource.attributes = RmdPublication.new(autocomplete_work_form_params[:doi]).to_params
        process_response(on_error: :edit)
      end

      private

        def autocomplete_work_form_params
          params
            .require(:autocomplete_work_form)
            .permit(
              :doi
            )
        end

        def work_version_params
          params
            .require(:work_version)
            .permit(
              :description,
              :publisher_statement,
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
              source: []
            )
        end

        def next_page_path
          dashboard_form_contributors_path('work_version', @resource.id)
        end

        def work_version
          @work_version ||= WorkVersion.includes(:work).find(params[:id])
        end

        def deposit_pathway
          @deposit_pathway ||= WorkDepositPathway.new(work_version)
        end
    end
  end
end
