# frozen_string_literal: true

module Dashboard
  module WorkForm
    class DetailsController < BaseController
      def new
        @work_version = WorkVersion.build_with_empty_work(depositor: current_user.actor)
      end

      def create
        @work_version = WorkVersion.build_with_empty_work(work_version_params, depositor: current_user.actor)

        respond_to do |format|
          if update_or_save_work_version
            format.html do
              redirect_upon_success
            end
            format.json { render :show, status: :created, location: @work_version.work }
          else
            format.html { render :new }
            format.json { render json: @work.errors, status: :unprocessable_entity }
          end
        end
      end

      def edit
        @work_version = policy_scope(WorkVersion).includes(:work).find(params[:work_version_id])
        authorize(@work_version)
      end

      def update
        @work_version = policy_scope(WorkVersion).includes(:work).find(params[:work_version_id])
        authorize(@work_version)

        @work_version.attributes = work_version_params

        respond_to do |format|
          if update_or_save_work_version
            format.html do
              redirect_upon_success
            end
            format.json { render :show, status: :ok, location: @work_version }
          else
            format.html { render :edit }
            format.json { render json: @work_version.errors, status: :unprocessable_entity }
          end
        end
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
          dashboard_work_form_contributors_path(@work_version)
        end
    end
  end
end
