# frozen_string_literal: true

module Dashboard
  class ProfilesController < BaseController
    def edit
      @creator = Creator.find_or_create_by_user(current_user)
    end

    def update
      @creator = Creator.find_or_create_by_user(current_user)

      if @creator.update(creator_params)
        redirect_to dashboard_works_path,
                    notice: t('dashboard.profiles.update.success')
      else
        render :edit
      end
    end

    private

      def creator_params
        params
          .require(:creator)
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
