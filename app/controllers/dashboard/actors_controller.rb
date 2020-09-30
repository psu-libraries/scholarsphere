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

      if @actor.save
        render json: { actor_id: @actor.id }
      else
        render :new
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
            :psu_id
          )
      end

      # @note All views are modal-only
      def determine_layout; end
  end
end
