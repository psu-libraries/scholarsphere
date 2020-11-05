# frozen_string_literal: true

class IncidentMailer < ApplicationMailer
  def report(incident)
    return unless incident.valid?

    @incident = incident
    mail(@incident.headers)
  end

  def acknowledgment(incident)
    return unless incident.email.match?(/psu\.edu$/)

    mail(
      to: incident.email,
      subject: "#{Rails.configuration.subject_prefix} #{incident.subject}"
    )
  end
end
