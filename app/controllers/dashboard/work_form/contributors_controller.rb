# frozen_string_literal: true

module Dashboard
  module WorkForm
    class ContributorsController < BaseController
      def edit
        @work_version = policy_scope(WorkVersion).find(params[:work_version_id])
        authorize(@work_version)

        @work_version.build_creator_alias(actor: current_user.actor) if @work_version.creators.empty?
      end

      def update
        @work_version = policy_scope(WorkVersion).find(params[:work_version_id])
        authorize(@work_version)

        @work_version.attributes = work_version_params

        respond_to do |format|
          if @work_version.save
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
              contributor: [],
              creator_aliases_attributes: [
                :id,
                :actor_id,
                :_destroy,
                :alias,
                actor_attributes: [
                  :id,
                  :email,
                  :given_name,
                  :surname,
                  :psu_id
                ]
              ]
            )
        end

        def next_page_path
          dashboard_work_form_files_path(@work_version)
        end
    end
  end
end
