# frozen_string_literal: true

# @abstract This controller is used exclusively to render only an html snippet that is appended to the contributors
# portion of the work form

module Dashboard
  module WorkForm
    class AliasesController < BaseController
      def new
        creator_alias = WorkVersionCreation.new(actor: alias_actor)
        render partial: 'dashboard/work_form/contributors/creator_alias_fields',
               locals: { creator_alias: creator_alias }
      end

      private

        # @note These are the same attributes that come from Qa::Authorities::Persons, with a few additions to make
        # the form work. The Qa module returns a json object for each person found, which is then passed directly on
        # to this controller for processing.
        def alias_params
          params
            .permit(
              :work_version_id,
              :actor_id,
              :email,
              :given_name,
              :surname,
              :psu_id,
              :default_alias,
              :orcid,
              :source,
              :index
            )
        end

        def alias_actor
          Actor.find(alias_params[:actor_id])
        rescue ActiveRecord::RecordNotFound
          Actor.new(alias_params.slice(:given_name, :email, :surname, :psu_id, :default_alias, :orcid))
        end
    end
  end
end
