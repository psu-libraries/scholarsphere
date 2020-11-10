# frozen_string_literal: true

module Dashboard
  class WorksController < BaseController
    layout 'frontend'

    def edit
      @undecorated_work = Work.find(params[:id])
      authorize(@undecorated_work)
      initialize_forms
    end

    def update
      @undecorated_work = Work.find(params[:id])
      authorize(@undecorated_work)
      initialize_forms

      form = select_form_model

      if form.save
        redirect_to edit_dashboard_work_path(@undecorated_work), notice: t('.success')
      else
        render :edit
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

      def initialize_forms
        @work = WorkDecorator.new(@undecorated_work)
        @work.attributes = work_params

        @embargo_form = EmbargoForm.new(work: @undecorated_work, params: embargo_params)
      end

      def select_form_model
        if params[:embargo_form].present?
          @embargo_form
        else
          @work
        end
      end

      # Never trust parameters from the scary internet, only allow the white list through.
      def work_params
        params
          .fetch(:work, {})
          .permit(
            :visibility
          )
      end

      def embargo_params
        params
          .fetch(:embargo_form, {})
          .permit(
            :embargoed_until,
            :remove
          )
      end
  end
end
