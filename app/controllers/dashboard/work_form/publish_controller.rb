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

        # If the user clicks the "Publish" button, *and* there are validation
        # errors, we still want to persist any changes to the draft version's
        # db record, while at the same time showing the publish validation errors
        #
        # The easiest way to do this is to immediately save all the form changes
        # against the draft validations, then mark the record as published and
        # save again--this time using the published validations. That way the
        # approriate error messages will appear on the form when it's re-rendered
        if publish_work?
          update_or_save_work_version
          @work_version.publish
        end

        respond_to do |format|
          if update_or_save_work_version
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
