# frozen_string_literal: true

module Dashboard
  class WorksController < BaseController

    end


      end
    end

    # DELETE /works/1
    # DELETE /works/1.json
    def destroy
      @work = current_user.works.find(params[:id])
      @work.destroy
      respond_to do |format|
        format.html { redirect_to dashboard_root_path, notice: 'Work was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    private

      # Never trust parameters from the scary internet, only allow the white list through.
      def work_params
        params
          .require(:work)
          .permit(
            :work_type,
            :visibility,
            versions_attributes: [
              :title
            ]
          )
      end
  end
end
