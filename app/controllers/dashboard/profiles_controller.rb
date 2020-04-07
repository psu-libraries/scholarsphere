# frozen_string_literal: true

module Dashboard
  class ProfilesController < BaseController
    def edit
      @actor = current_user.actor
    end

    def update
      @actor = current_user.actor

      if @actor.update(creator_params)
        redirect_to dashboard_works_path,
                    notice: t('dashboard.profiles.update.success')
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
            :default_alias,
            :email,
            :orcid
          )
      end
  end
end
