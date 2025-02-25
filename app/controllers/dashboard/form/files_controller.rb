# frozen_string_literal: true

module Dashboard
  module Form
    class FilesController < BaseController
      def edit
        @resource = WorkVersion
          .includes(file_version_memberships: [:file_resource])
          .find(params[:id])
        authorize(@resource)
      end

      def update
        @resource = WorkVersion.find(params[:id])
        authorize(@resource)
        @resource.attributes = work_version_params
        process_response(on_error: :edit) do
          send_accessibility_check_jobs
        end
      end

      private

        def work_version_params
          params
            .require(:work_version)
            .permit(
              file_resources_attributes: [
                :file
              ]
            )
        end

        def next_page_path
          dashboard_form_publish_path(@resource)
        end

        def send_accessibility_check_jobs
          @resource.file_resources.needs_accessibility_check.each do |file_resource|
            AccessibilityCheckJob.perform_later(file_resource.id)
          end
        end
    end
  end
end
