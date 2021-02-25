# frozen_string_literal: true

# @abstract This controller is used exclusively to render only an html snippet that is appended to forms with
# creators

module Dashboard
  module Form
    class AuthorshipsController < BaseController
      def new
        render partial: 'dashboard/form/contributors/authorship_fields',
               locals: { authorship: authorship }
      end

      private

        # @note These are the same attributes that come from Qa::Authorities::Persons, with a few additions to make
        # the form work. The Qa module returns a json object for each person found, which is then passed directly on
        # to this controller for processing.
        def authorship_params
          params
            .permit(
              :id,
              :actor_id,
              :email,
              :given_name,
              :surname,
              :psu_id,
              :display_name,
              :orcid,
              :source,
              :index
            )
        end

        def actor
          return unless params[:psu_id].present? || params[:orcid].present?

          Actor.find(authorship_params[:actor_id])
        rescue ActiveRecord::RecordNotFound
          Actor.new(authorship_params.slice(:given_name, :email, :surname, :psu_id, :display_name, :orcid))
        end

        def authorship
          Authorship.new(
            display_name: authorship_params['display_name'],
            given_name: authorship_params['given_name'],
            surname: authorship_params['surname'],
            email: authorship_params['email'],
            actor: actor
          )
        end
    end
  end
end
