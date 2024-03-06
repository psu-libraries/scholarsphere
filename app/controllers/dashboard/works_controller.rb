# frozen_string_literal: true

module Dashboard
  class WorksController < BaseController
    layout 'frontend'

    after_action :update_index, only: [:update]

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

    helper_method :deposit_pathway

    private

      # @note Work indexing is largely handled via the WorkVersion and not the actual work. Placing a callback on the
      # Work could interfere with that process, so instead we reindex the work directly here in the controller.
      def update_index
        WorkIndexer.call(@undecorated_work, commit: true)
      end

      def initialize_forms
        @work = WorkDecorator.new(@undecorated_work)
        @work.attributes = work_params if deposit_pathway.allows_visibility_change?

        @embargo_form = EmbargoForm.new(work: @undecorated_work, params: embargo_params)
        @editors_form = EditorsForm.new(resource: @undecorated_work, user: current_user, params: editors_params)
        @depositor_form = DepositorForm.new(resource: @undecorated_work, params: depositor_params) if current_user.admin?
        @curator_form = CuratorForm.new(resource: @undecorated_work, params: curator_params) if current_user.admin?
        @withdraw_versions_form = WithdrawVersionsForm.new(work: @undecorated_work, params: withdraw_versions_params)
        @thumbnail_form = ThumbnailForm.new(resource: @undecorated_work, params: thumbnail_params)
      end

      def select_form_model
        if params[:embargo_form].present?
          @embargo_form
        elsif params[:editors_form].present?
          @editors_form
        elsif params[:depositor_form].present?
          @depositor_form
        elsif params[:curator_form].present?
          @curator_form
        elsif params[:withdraw_versions_form].present?
          @withdraw_versions_form
        elsif params[:thumbnail_form].present?
          @thumbnail_form
        else
          @work
        end
      end

      def deposit_pathway
        @deposit_pathway ||= WorkDepositPathway.new(@undecorated_work)
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

      def editors_params
        params
          .fetch(:editors_form, {})
          .permit(
            :notify_editors,
            edit_users: [],
            edit_groups: []
          )
      end

      def depositor_params
        params
          .fetch(:depositor_form, {})
          .permit(
            :psu_id
          )
      end

      def curator_params
        params
          .fetch(:curator_form, {})
          .permit(
            :access_id
          )
      end

      def withdraw_versions_params
        params
          .fetch(:withdraw_versions_form, {})
          .permit(
            :work_version_id
          )
      end

      def thumbnail_params
        params
          .fetch(:thumbnail_form, {})
          .permit(
            :thumbnail_selection,
            :thumbnail_upload
          )
      end
  end
end
