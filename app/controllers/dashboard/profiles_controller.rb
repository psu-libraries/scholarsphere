# frozen_string_literal: true

module Dashboard
  class ProfilesController < BaseController
    def edit
      @actor = current_user.actor
    end

    def update
      @actor = current_user.actor

      if @actor.update(creator_params)
        redirect_to dashboard_root_path,
                    notice: t('.success')
      else
        render :edit
      end
    end

    private

      def creator_params
        params
          .require(:actor)
          .permit(
            :given_name,
            :surname,
            :display_name,
            :email,
            user_attributes: [
              :id,
              :admin_enabled,
              :opt_in_stats_email
            ]
          )
      end
  end
end
