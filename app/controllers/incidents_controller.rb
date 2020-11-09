# frozen_string_literal: true

class IncidentsController < ApplicationController
  before_action :check_recaptcha, only: :create

  def new
    @incident = Incident.new(name: user_name, email: current_user.email)
  end

  def create
    if incident.valid?
      IncidentMailer.report(incident).deliver_now
      IncidentMailer.acknowledgment(incident).deliver_now
      redirect_to root_path, notice: I18n.t('incidents.create.success')
    else
      render :new
    end
  end

  private

    def incident
      @incident ||= Incident.new(incident_params)
    end

    def user_name
      return if current_user.guest?

      current_user.display_name
    end

    def incident_params
      params
        .require(:incident)
        .permit(
          :category,
          :name,
          :email,
          :subject,
          :message
        )
    end

    def check_recaptcha
      return if verify_recaptcha(model: incident)

      render :new
    end

    def determine_layout
      'frontend'
    end
end
