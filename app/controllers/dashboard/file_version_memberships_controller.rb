# frozen_string_literal: true

module Dashboard
  class FileVersionMembershipsController < BaseController
    before_action :load_file_resource

    def edit
      authorize(@work_version)
    end

    def update
      authorize(@work_version)
      if @file_version.update(file_version_params)
        respond_to do |format|
          format.html do
            redirect_to dashboard_form_files_path(@work_version),
                        notice: 'File was successfully updated.'
          end
          format.json { render json: @file_version }
        end
      else
        respond_to do |format|
          format.html { render :edit }
          format.json { render json: @file_version.errors, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      authorize(@work_version)
      @file_version.destroy
      respond_to do |format|
        format.html do
          redirect_to dashboard_form_files_path(@work_version),
                      notice: 'Work version was successfully destroyed.'
        end
        format.json { head :no_content }
      end
    end

    private

      def load_file_resource
        @file_version = FileVersionMembership.find(params[:id])
        @work_version = @file_version.work_version
      end

      def file_version_params
        params
          .require(:file_version_membership)
          .permit(:title)
      end
  end
end
