# frozen_string_literal: true

module Dashboard
  class ActorsController < BaseController
    # GET /dashboard/actors/new
    def new
      @actor = Actor.new
      authorize(@actor)

      render :new, layout: false
    end

    # POST /dashboard/actors
    def create
      @actor = Actor.new(actor_params)
      authorize(@actor)

      if @actor.save(context: :from_user)
        render json: { actor_id: @actor.id }
      else
        render :new, status: :unprocessable_entity, layout: false
      end
    end

    private

      def actor_params
        params
          .require(:actor)
          .permit(
            :surname,
            :given_name,
            :email,
            :orcid
          )
      end

      # @note All views are modal-only
      def determine_layout; end
  end
end
