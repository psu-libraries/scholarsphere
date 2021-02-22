# frozen_string_literal: true

module Dashboard
  module Form
    class ContributorsController < ::Dashboard::Form::BaseController
      def edit
        @resource = resource_klass.find(params[:id])
        authorize(@resource)
        @resource.build_creator(actor: current_user.actor) if @resource.creators.empty?
      end

      def update
        @resource = resource_klass.find(params[:id])
        authorize(@resource)
        @resource.attributes = resource_params
        process_response(on_error: :edit)
      end

      private

        def resource_params
          params
            .require(param_key)
            .permit(
              contributor: [],
              creators_attributes: [
                :id,
                :actor_id,
                :_destroy,
                :display_name,
                :position,
                :given_name,
                :surname,
                :email,
                actor_attributes: [
                  :id,
                  :email,
                  :given_name,
                  :surname,
                  :psu_id,
                  :orcid
                ]
              ]
            )
        end

        def next_page_path
          if @resource.is_a?(Collection)
            dashboard_form_members_path(@resource)
          else
            dashboard_form_files_path(@resource)
          end
        end
    end
  end
end
