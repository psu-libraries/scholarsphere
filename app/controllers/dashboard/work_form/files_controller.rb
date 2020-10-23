# frozen_string_literal: true

module Dashboard
  module WorkForm
    class FilesController < BaseController
      def edit
        @work_version = WorkVersion
          .includes(file_version_memberships: [:file_resource])
          .find(params[:work_version_id])
        authorize(@work_version)
      end

      def update
        @work_version = WorkVersion.find(params[:work_version_id])
        authorize(@work_version)
        if update_or_save_work_version(attributes: work_version_params)
          redirect_upon_success
        else
          render :edit
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
          dashboard_work_form_publish_path(@work_version)
        end
    end
  end
end
