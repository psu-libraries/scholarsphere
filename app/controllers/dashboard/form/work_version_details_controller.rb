# frozen_string_literal: true

module Dashboard
  module Form
    class WorkVersionDetailsController < BaseController
      before_action :set_autocomplete_form

      def self._prefixes
        ['application', 'dashboard/form', 'dashboard/form/details']
      end

      def edit
        authorize(work_version)
        @resource = deposit_pathway.details_form
      end

      def update
        authorize(work_version)
        @resource = deposit_pathway.details_form
        @resource.attributes = work_version_params
        process_response(on_error: :edit)
      end

      def autocomplete_work_forms
        authorize(work_version, :edit?)
        @resource = deposit_pathway.details_form
        AutopopulateWorkVersionService.new(work_version, autocomplete_work_form_params[:doi]).call
        work_version.update imported_metadata_from_rmd: true
        redirect_to dashboard_form_work_version_details_url(@resource.id),
                        notice: I18n.t('dashboard.form.notices.autocomplete_successful')
      rescue RmdPublication::PublicationNotFound
        work_version.update imported_metadata_from_rmd: false
        flash[:error] = 'We were not able to find metadata for your submission'
        render :edit
      end

      private

        def set_autocomplete_form
          @autocomplete_work_form = AutocompleteWorkForm.new
        end

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
    end
  end
end
