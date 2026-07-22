# frozen_string_literal: true

module Admin
  class ApplicationSettingsController < ApplicationController
    # GET /application_settings
    def edit
      @application_setting = ApplicationSetting.instance
    end

    # PATCH/PUT /application_settings
    def update
      @application_setting = ApplicationSetting.instance
      respond_to do |format|
        if @application_setting.update(application_setting_params)
          format.html { redirect_to admin_application_settings_url, notice: 'Settings were successfully updated.' }
        else
          format.html { render :edit }
        end
      end
    end

    private

      # Only allow a list of trusted parameters through.
      def application_setting_params
        params.require(:application_setting).permit(:read_only_message, :announcement)
      end
  end
end
