# frozen_string_literal: true

module Dashboard
  class FileListsController < BaseController
    before_action :load_work_version

    def edit
      authorize(@work_version)
      @file_version_memberships = @work_version.file_version_memberships.includes(:file_resource)
    end

    def update
      authorize(@work_version)
      if @work_version.update(work_version_params)
        redirect_to edit_dashboard_work_version_path(@work_version)
      else
        render :edit
      end
    end

    private

      def load_work_version
        @work_version = WorkVersion.find(params[:work_version_id])
      end

      def work_version_params
        params
          .require(:work_version)
          .permit(
            file_resources_attributes: [
              :file
            ]
          )
      end
  end
end
