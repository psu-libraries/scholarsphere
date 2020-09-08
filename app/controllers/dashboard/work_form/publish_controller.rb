# frozen_string_literal: true

module Dashboard
  module WorkForm
    class PublishController < BaseController
      def edit
        @work_version = policy_scope(WorkVersion)
          .includes(file_version_memberships: [:file_resource])
          .find(params[:work_version_id])
        authorize(@work_version)

        @work_version.publish
        @work_version.validate
      end

      def update
        @work_version = policy_scope(WorkVersion).find(params[:work_version_id])
        authorize(@work_version)

        @work_version.attributes = work_version_params

        @work_version.publish if publish_work?

        respond_to do |format|
          if @work_version.save
            format.html do
              notice = if publish_work?
                         'Successfully published work!'
                       else
                         'Work version was successfully updated.'
                       end
              redirect_to dashboard_root_path, notice: notice
            end
            format.json { render :show, status: :ok, location: @work_version }
          else
            format.html { render :edit }
            format.json { render json: @work_version.errors, status: :unprocessable_entity }
          end
        end
      end

      private

        def publish_work?
          !save_and_exit?
        end

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
              :depositor_agreement,
              keyword: [],
              contributor: [],
              publisher: [],
              subject: [],
              language: [],
              identifier: [],
              based_near: [],
              related_url: [],
              source: [],
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
              ],
              work_attributes: [
                :id,
                :work_type,
                :visibility
              ]
            )
        end
    end
  end
end
